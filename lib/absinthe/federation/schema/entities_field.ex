defmodule Absinthe.Federation.Schema.EntitiesField do
  @moduledoc false

  alias Absinthe.Adapter.LanguageConventions
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

    resolvers =
      resolutions
      |> Enum.group_by(fn %{middleware: [middleware | _remaining_middleware]} = r ->
        case middleware do
          {Absinthe.Middleware.Dataloader, {loader, _fun}} ->
            {source, _} = find_relevant_dataloader(loader)
            {:dataloader, source}

          _ ->
            {:resolver, r}
        end
      end)
      |> Enum.flat_map(fn
        {{:dataloader, _}, v} = _resolvers -> Enum.take(v, 1)
        {{:resolver, _}, v} = _resolvers -> v
      end)

    value =
      resolvers
      |> Enum.map(&reduce_resolution/1)
      |> List.flatten()
      |> Map.new()

    res =
      resolution.arguments.representations
      |> Enum.reduce(%{errors: [], value: []}, fn r, acc ->
        case Map.get(value, r) do
          {:error, err} -> Map.update!(acc, :errors, &[err | &1])
          result -> Map.update!(acc, :value, &[result | &1])
        end
      end)

    %{
      resolution
      | state: :resolved,
        errors: Enum.reverse(res[:errors]),
        value: Enum.reverse(res[:value])
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

    resolution = Map.put(resolution, :arguments, Map.put(resolution.arguments, :representation, representation))

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

  defp resolve_reference(nil, _parent, representation, %{context: context} = _resolution) do
    args = convert_keys_to_atom(representation, context)

    fn _, _ -> {:ok, args} end
  end

  defp resolve_reference(
         %{middleware: middleware},
         parent,
         representation,
         %{schema: schema, context: context} = resolution
       ) do
    args = convert_keys_to_atom(representation, context)

    middleware
    |> Absinthe.Middleware.unshim(schema)
    |> Enum.find(nil, &only_resolver_middleware/1)
    |> case do
      {_, resolve_ref_func} when is_function(resolve_ref_func, 2) ->
        fn _, _ -> resolve_ref_func.(args, resolution) end

      {_, resolve_ref_func} when is_function(resolve_ref_func, 3) ->
        fn _, _ -> resolve_ref_func.(parent, args, resolution) end

      _ ->
        fn _, _ -> {:ok, args} end
    end
  end

  defp convert_keys_to_atom(map, context) when is_map(map) do
    Map.new(map, fn {k, v} ->
      k = convert_key(k, context)
      v = convert_keys_to_atom(v, context)
      {k, v}
    end)
  end

  defp convert_keys_to_atom(v, _context), do: v

  defp convert_key(k, context) do
    adapter = Map.get(context, :adapter, LanguageConventions)

    if adapter_has_to_internal_name_modifier?(adapter) do
      adapter.to_internal_name(k, :field)
    else
      k
    end
    |> String.to_atom()
  end

  defp adapter_has_to_internal_name_modifier?(adapter) do
    Keyword.get(adapter.__info__(:functions), :to_internal_name) == 2
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
      nil -> {res.arguments.representation, {:error, res.errors |> List.first()}}
      _ -> {res.arguments.representation, res.value}
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

    representations =
      args
      |> Enum.reject(fn arg ->
        Map.get(arg, "__typename") != typename
      end)

    ids =
      representations
      |> Enum.map(fn arg -> Map.get(arg, key_field) end)

    loader
    |> Dataloader.load_many(source, %{__typename: typename}, ids)
    |> Dataloader.run()
    |> Dataloader.get_many(source, %{__typename: typename}, ids)
    |> Enum.zip(representations)
    |> Enum.map(fn {res, arg} ->
      case res do
        {:ok, data} -> {arg, data}
        {:error, _} = e -> {arg, e}
        data -> {arg, data}
      end
    end)
  end

  defp call_middleware({_mod, {fun, args}}, resolution) do
    with {:ok, res} <- fun.(args) do
      {resolution.arguments.representation, res}
    else
      err -> {resolution.arguments.representation, err}
    end
  end

  defp find_relevant_dataloader(%Dataloader{sources: sources}) do
    {source, loader} =
      Enum.find(sources, fn {_, source} ->
        Dataloader.Source.pending_batches?(source)
      end)

    %{batches: batches} = loader
    {{:_entities, %{__typename: typename}}, _} = Enum.at(batches, 0)
    {source, typename}
  end
end
