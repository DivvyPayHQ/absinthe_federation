defmodule Absinthe.Federation.Schema.EntityUnion do
  @moduledoc false

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema.UnionTypeDefinition
  alias Absinthe.Blueprint.TypeReference.Name
  alias Absinthe.Schema.Notation
  alias Absinthe.Type

  require Protocol

  def build(blueprint) do
    %UnionTypeDefinition{
      __reference__: Notation.build_reference(__ENV__),
      description: "a union of all types that use the @key directive",
      identifier: :_entity,
      module: __MODULE__,
      name: "_Entity",
      types: types(blueprint),
      resolve_type: &__MODULE__.resolve_type/2
    }
  end

  def resolve_type(map, resolution) do
    Absinthe.Federation.Schema.EntityUnion.Resolver.resolve_type(map, resolution)
  end

  defp types(node) do
    {_node, types} = Blueprint.postwalk(node, [], &collect_types/2)

    types
  end

  defp collect_types(
         %{name: name, __private__: _private} = node,
         types
       ) do
    if has_key_directive?(node) do
      {node, [%Name{name: name} | types]}
    else
      {node, types}
    end
  end

  defp collect_types(node, acc), do: {node, acc}

  defp has_key_directive?(node) do
    meta = Type.meta(node)
    has_meta_key = Map.has_key?(meta, :key_fields)
    node_directives = Map.get(node, :directives, [])
    has_key_directive = Enum.any?(node_directives, &is_key_directive?/1)
    has_meta_key or has_key_directive
  end

  defp is_key_directive?(%{name: "key"} = _directive), do: true
  defp is_key_directive?(_directive), do: false
end

defprotocol Absinthe.Federation.Schema.EntityUnion.Resolver do
  @fallback_to_any true
  def resolve_type(map, resolution)
end

defimpl Absinthe.Federation.Schema.EntityUnion.Resolver, for: Any do
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

  def resolve_type(%struct_name{}, _resolution) do
    struct_name
    |> Module.split()
    |> List.last()
    |> String.downcase()
    |> String.to_existing_atom()
  end
end
