defmodule Absinthe.Federation.Schema.EntitiesField do
  @moduledoc false

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.Schema.InputValueDefinition
  alias Absinthe.Blueprint.TypeReference.List, as: ListType
  alias Absinthe.Blueprint.TypeReference.Name
  alias Absinthe.Blueprint.TypeReference.NonNull
  alias Absinthe.Schema.Notation

  # TODO: Fix __reference__ typespec upstream in absinthe
  @type input_value_definition :: %InputValueDefinition{
          name: String.t(),
          description: nil | String.t(),
          type: Blueprint.TypeReference.t(),
          default_value: nil | Blueprint.Input.t(),
          default_value_blueprint: Blueprint.Draft.t(),
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # The struct module of the parent
          placement: :argument_definition | :input_field_definition,
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()],
          __reference__: nil | map()
        }

  @type field_definition :: %FieldDefinition{
          name: String.t(),
          identifier: atom,
          description: nil | String.t(),
          deprecation: nil | Blueprint.Schema.Deprecation.t(),
          arguments: [input_value_definition()],
          type: Blueprint.TypeReference.t(),
          directives: [Blueprint.Directive.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          # Added by DSL
          description: nil | String.t(),
          middleware: [any],
          # Added by phases
          flags: Blueprint.flags_t(),
          errors: [Absinthe.Phase.Error.t()],
          triggers: [],
          module: nil | module(),
          function_ref: nil | function(),
          default_value: nil | any(),
          config: nil,
          complexity: nil,
          __reference__: nil | map(),
          __private__: []
        }

  @spec build() :: field_definition()
  def build() do
    %FieldDefinition{
      __reference__: Notation.build_reference(__ENV__),
      description: """
      Returns a non-nullable list of _Entity types
      and have a single argument with an argument name of representations
      and type [_Any!]! (non-nullable list of non-nullable _Any scalars).
      The _entities field on the query root must allow a list of _Any scalars
      which are "representations" of entities from external services.
      These representations should be validated with the following rules:

      - Any representation without a __typename: String field is invalid.
      - Representations must contain at least the fields defined in the fieldset of a @key directive on the base type.
      """,
      identifier: :_entities,
      module: __MODULE__,
      name: "_entities",
      type: %NonNull{
        of_type: %ListType{
          of_type: %Name{
            name: "_Entity"
          }
        }
      },
      middleware: [__MODULE__],
      arguments: build_arguments()
    }
  end

  def call(%{state: :unresolved} = resolution, _args) do
    resolutions = resolver(resolution.source, resolution.arguments, resolution)

    value =
      Enum.uniq_by(resolutions, fn %{middleware: [middleware | _remaining_middleware]} = r ->
        case middleware do
          {Absinthe.Middleware.Dataloader, {loader, _fun}} ->
            {source, _} = find_relevant_dataloader(loader)
            source

          _ ->
            r
        end
      end)
      |> Enum.map(&reduce_resolution/1)
      |> List.flatten()

    res =
      value
      |> Enum.reduce(%{errors: [], value: []}, fn r, acc ->
        case r do
          {:error, err} -> Map.update(acc, :errors, [], fn v -> v ++ [err] end)
          value -> Map.update(acc, :value, [], fn v -> v ++ [value] end)
        end
      end)

    %{
      resolution
      | state: :resolved,
        errors: Map.get(res, :errors),
        value: Map.get(res, :value)
    }
  end

  def call(res, _args), do: res

  def resolver(parent, %{representations: representations}, resolution) do
    Enum.map(representations, &entity_accumulator(&1, parent, resolution))
  end

  defp entity_accumulator(representation, parent, %{schema: schema} = resolution) do
    typename = Map.get(representation, "__typename")

    fun =
      schema
      |> Absinthe.Schema.lookup_type(typename)
      |> resolve_representation(parent, representation, resolution)

    Absinthe.Resolution.call(resolution, fun)
  end

  defp resolve_representation(
         %struct_type{fields: fields},
         parent,
         representation,
         resolution
       )
       when struct_type in [Absinthe.Type.Object, Absinthe.Type.Interface],
       do: resolve_reference(fields[:_resolve_reference], parent, representation, resolution)

  defp resolve_representation(_schema_type, _parent, representation, _schema),
    do:
      {:error,
       "The _entities resolver tried to load an entity for type '#{Map.get(representation, "__typename")}', but no object type of that name was found in the schema"}

  defp resolve_reference(nil, _parent, representation, _resolution), do: {:ok, representation}

  defp resolve_reference(%{middleware: middleware}, parent, representation, %{schema: schema} = resolution) do
    args = for {key, val} <- representation, into: %{}, do: {String.to_atom(key), val}

    middleware
    |> Absinthe.Middleware.unshim(schema)
    |> Enum.filter(&only_resolver_middleware/1)
    |> List.first()
    |> case do
      {_, resolve_ref_func} when is_function(resolve_ref_func, 2) ->
        fn _, _ -> resolve_ref_func.(args, resolution) end

      {_, resolve_ref_func} when is_function(resolve_ref_func, 3) ->
        fn _, _ -> resolve_ref_func.(parent, args, resolution) end

      _ ->
        {:ok, representation}
    end
  end

  defp only_resolver_middleware({{Absinthe.Resolution, :call}, _}), do: true

  defp only_resolver_middleware(_), do: false

  defp build_arguments(), do: [build_argument()]

  defp build_argument(),
    do: %InputValueDefinition{
      __reference__: Notation.build_reference(__ENV__),
      identifier: :representations,
      module: __MODULE__,
      name: "representations",
      placement: :argument_definition,
      type: %NonNull{
        of_type: %ListType{
          of_type: %NonNull{
            of_type: %Name{
              name: "_Any"
            }
          }
        }
      }
    }

  defp reduce_resolution(%{state: :resolved} = res) do
    case res.value do
      nil -> {:error, res.errors |> List.first()}
      _ -> res.value
    end
  end

  defp reduce_resolution(%{middleware: []} = res), do: res

  defp reduce_resolution(%{middleware: [middleware | remaining_middleware]} = res) do
    call_middleware(middleware, %{res | middleware: remaining_middleware})
  end

  defp call_middleware({Absinthe.Middleware.Dataloader, {loader, _fun}}, %{
         arguments: %{representations: args},
         schema: schema
       }) do
    {source, typename} = find_relevant_dataloader(loader)

    key_field =
      Absinthe.Schema.lookup_type(schema, typename)
      |> Absinthe.Type.meta()
      |> Map.get(:key_fields, "id")

    ids =
      args
      |> Enum.reject(fn arg ->
        Map.get(arg, "__typename") != typename
      end)
      |> Enum.map(fn arg -> Map.get(arg, key_field) end)

    loader
    |> Dataloader.load_many(source, %{__typename: typename}, ids)
    |> Dataloader.run()
    |> Dataloader.get_many(source, %{__typename: typename}, ids)
    |> Enum.map(fn res ->
      case res do
        {:ok, data} -> data
        {:error, _} = e -> e
        nil -> nil
      end
    end)
  end

  defp call_middleware({_mod, {fun, args}}, _res) do
    with {:ok, res} <- fun.(args) do
      res
    end
  end

  defp find_relevant_dataloader(%Dataloader{sources: sources}) do
    {source, loader} =
      Enum.find(sources, fn {_, %{batches: batches}} ->
        length(Map.values(batches)) > 0
      end)

    %{batches: batches} = loader
    {:_entities, representation} = batches |> Map.keys() |> List.first()
    {source, Map.get(representation, :__typename)}
  end
end
