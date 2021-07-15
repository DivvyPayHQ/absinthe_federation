defmodule Absinthe.Federation.Schema.EntityUnion do
  @moduledoc false

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema.UnionTypeDefinition
  alias Absinthe.Schema.Notation

  alias Absinthe.Federation.Schema.Utils

  @spec build(Blueprint.t()) :: UnionTypeDefinition.t() | nil
  def build(blueprint) do
    case Utils.key_field_types(blueprint) do
      [] ->
        nil

      found_types ->
        %UnionTypeDefinition{
          __reference__: Notation.build_reference(__ENV__),
          description: "a union of all types that use the @key directive",
          identifier: :_entity,
          module: __MODULE__,
          name: "_Entity",
          types: found_types,
          resolve_type: &Absinthe.Federation.Schema.EntityUnion.resolve_type/2
        }
    end
  end

  # TODO: This is a very naive approach to resolve the union type and should be replaced by something better
  # Should the library consumer be required to define this union type since they will know how to resolve the types better than we can?
  def resolve_type(%struct_name{}, _resolution) do
    struct_name
    |> Module.split()
    |> List.last()
    |> String.downcase()
    |> String.to_existing_atom()
  end

  def resolve_type(%{__typename: typename}, _resolution) do
    typename
    |> Macro.underscore()
    |> String.to_existing_atom()
  end

  def resolve_type(%{"__typename" => typename}, _resolution) do
    typename
    |> Macro.underscore()
    |> String.to_existing_atom()
  end
end
