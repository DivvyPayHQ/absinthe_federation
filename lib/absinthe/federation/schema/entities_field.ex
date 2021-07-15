defmodule Absinthe.Federation.Schema.EntitiesField do
  @moduledoc false

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.Schema.InputValueDefinition
  alias Absinthe.Blueprint.TypeReference.List, as: ListType
  alias Absinthe.Blueprint.TypeReference.Name
  alias Absinthe.Blueprint.TypeReference.NonNull
  alias Absinthe.Schema.Notation

  alias Absinthe.Federation.Schema.Utils

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

  @spec build(Blueprint.t()) :: field_definition() | nil
  def build(blueprint) do
    case Utils.key_field_types(blueprint) do
      [] ->
        nil

      _found_types ->
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
          middleware: [{Absinthe.Resolution, &__MODULE__.resolver/3}],
          arguments: build_arguments()
        }
    end
  end

  def resolver(parent, %{representations: representations}, resolution) do
    Enum.reduce_while(representations, {:ok, []}, &entity_accumulator(&1, &2, parent, resolution))
  end

  defp entity_accumulator(representation, {:ok, entities}, parent, %{schema: schema} = resolution) do
    typename = Map.get(representation, "__typename")

    schema
    |> Absinthe.Schema.lookup_type(typename)
    |> resolve_representation(parent, representation, resolution)
    |> case do
      {:ok, entity} ->
        {:cont, {:ok, entities ++ [entity]}}

      {:error, _} = error ->
        {:halt, error}
    end
  end

  defp entity_accumulator(_representation, result, _parent, _schema), do: result

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
        resolve_ref_func.(args, resolution)

      {_, resolve_ref_func} when is_function(resolve_ref_func, 3) ->
        resolve_ref_func.(parent, args, resolution)

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
end
