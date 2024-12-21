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
    resolution_acc = resolution_accumulator(resolution)

    # Run pre-resolution plugins, such as async/batch and dataloader.
    resolution_acc = run_callbacks(resolution_acc.schema.plugins(), :before_resolution, resolution_acc)

    representations_to_resolve =
      Enum.map(resolution.arguments.representations, &resolve_reference_field(&1, resolution_acc))

    # Resolve representations first time
    resolution_acc = Enum.reduce(representations_to_resolve, resolution_acc, &resolve_representation/2)

    # If any representation fields are suspended (i.e async or dataloaded),
    # run the plugins and resolve_representation pipeline again.
    resolution_acc =
      if Enum.any?(resolution_acc.path, &(&1.state == :suspended)) do
        representations_to_resolve = resolution_acc.path

        resolution_acc =
          run_callbacks(resolution_acc.schema.plugins(), :before_resolution, resolution_acc)
          |> Map.put(:path, [])

        Enum.reduce(representations_to_resolve, resolution_acc, &resolve_representation/2)
      else
        resolution_acc
      end

    # Run post-resolution plugins
    resolution_acc = run_callbacks(resolution_acc.schema.plugins(), :after_resolution, resolution_acc)
    representations = resolution_acc.path

    # Collect values and errors
    resolution_acc =
      Enum.reduce(representations, resolution_acc, fn representation, acc ->
        representation_errors = representation.errors
        representation_value = representation.value

        acc
        |> Map.update!(:value, fn value -> [representation_value | value] end)
        |> Map.update!(:errors, fn errors -> representation_errors ++ errors end)
      end)
      |> then(&reverse_values_and_errors/1)
      |> then(&set_final_state/1)

    %{resolution | state: resolution_acc.state, value: resolution_acc.value, errors: resolution_acc.errors}
  end

  defp reverse_values_and_errors(res) do
    res
    |> Map.update!(:value, &Enum.reverse/1)
    |> Map.update!(:errors, &Enum.reverse/1)
  end

  defp set_final_state(res) do
    if Enum.all?(res.path, &(&1.state == :resolved)) do
      Map.put(res, :state, :resolved)
    else
      paths = Enum.map(res.path, &%{state: &1.state, value: &1.value, errors: &1.errors})
      raise "Expected all fields to be resolved, but got: #{paths}"
    end
  end

  # These are the fields to be threaded through every single representation resolution.
  defp resolution_accumulator(resolution) do
    resolution
    |> Map.take([:context, :state, :acc, :fields_cache, :schema, :source])
    |> Map.put(:path, [])
    |> Map.put(:errors, [])
    |> Map.put(:value, [])
  end

  # Resolve a single representation and accumulate it to field resolution
  # under path key. If a field is already resolved, do not run any middlewares.
  defp resolve_representation(representation, acc) do
    if representation.state == :resolved do
      new_path = acc.path ++ [representation]

      acc
      |> Map.put(:path, new_path)
    else
      local_res =
        representation
        |> Map.put(:context, acc.context)
        |> Map.put(:acc, acc.acc)

      result = reduce_resolution(local_res)
      new_path = acc.path ++ [result]

      acc
      |> Map.put(:context, result.context)
      |> Map.put(:acc, result.acc)
      |> Map.put(:path, new_path)
    end
  end

  defp resolve_reference_field(representation, resolution_acc) do
    typename = Map.get(representation, "__typename")
    %{schema: schema, source: source, context: context} = resolution_acc
    args = convert_keys_to_atom(representation, context)

    field =
      schema
      |> Absinthe.Schema.lookup_type(typename)
      |> resolve_representation(source, representation)

    field
    |> Map.put(:arguments, args)
    |> Map.put(:schema, schema)
    |> Map.put(:source, source)
    |> Map.put(:state, :unresolved)
    |> Map.put(:value, nil)
    |> Map.put(:errors, [])
  end

  defp resolve_representation(%struct_type{fields: fields}, parent, _representation)
       when struct_type in [Absinthe.Type.Object, Absinthe.Type.Interface] do
    resolve_reference(fields[:_resolve_reference], parent)
  end

  defp resolve_representation(_schema_type, _parent, representation),
    do:
      {:error,
       "The _entities resolver tried to load an entity for type '#{Map.get(representation, "__typename")}', but no object type of that name was found in the schema"}

  defp resolve_reference(field, parent) do
    # When there is a field _resolve_reference, set it up so the resolution pipeline can be run
    # on it.
    if field do
      Map.put(field, :parent, parent)
    else
      # When there is no field name _resolve_reference defined on the key object, create
      # a stub middleware that returns arguments as the field resolution.
      middleware = {{Absinthe.Resolution, :call}, fn args, _res -> {:ok, args} end}
      %{middleware: [middleware], parent: parent}
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

  defp run_callbacks(plugins, callback, acc) do
    Enum.reduce(plugins, acc, &apply(&1, callback, [&2]))
  end

  defp reduce_resolution(%{middleware: []} = res), do: res

  defp reduce_resolution(%{middleware: [middleware | remaining_middleware]} = res) do
    case call_middleware(middleware, %{res | middleware: remaining_middleware}) do
      %{state: :suspended} = res ->
        res

      res ->
        reduce_resolution(res)
    end
  end

  defp call_middleware({{mod, fun}, opts}, res) do
    apply(mod, fun, [res, opts])
  end

  defp call_middleware({mod, opts}, res) do
    apply(mod, :call, [res, opts])
  end

  defp call_middleware(mod, res) when is_atom(mod) do
    apply(mod, :call, [res, []])
  end

  defp call_middleware(fun, res) when is_function(fun, 2) do
    fun.(res, [])
  end

  defp adapter_has_to_internal_name_modifier?(adapter) do
    Keyword.get(adapter.__info__(:functions), :to_internal_name) == 2
  end

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
end
