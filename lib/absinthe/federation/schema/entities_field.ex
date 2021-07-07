defmodule Absinthe.Federation.Schema.EntitiesField do
  @moduledoc false

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.Schema.InputValueDefinition
  alias Absinthe.Blueprint.TypeReference.List
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
        of_type: %List{
          of_type: %Name{
            name: "_Entity"
          }
        }
      },
      middleware: [{Absinthe.Resolution, &__MODULE__.resolver/3}],
      arguments: build_arguments()
    }
  end

  def resolver(_parent, _args, %{schema: _schema} = _resolution) do
    {:ok, %{}}
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
        of_type: %List{
          of_type: %NonNull{
            of_type: %Name{
              name: "_Any"
            }
          }
        }
      }
    }
end
