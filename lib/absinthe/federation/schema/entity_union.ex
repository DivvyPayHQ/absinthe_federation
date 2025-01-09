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
    if is_object_type?(node) and has_key_directive?(node) do
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

  defp is_object_type?(%Absinthe.Blueprint.Schema.ObjectTypeDefinition{}), do: true
  defp is_object_type?(_), do: false
end

defprotocol Absinthe.Federation.Schema.EntityUnion.Resolver do
  @fallback_to_any true
  def resolve_type(map, resolution)
end

defimpl Absinthe.Federation.Schema.EntityUnion.Resolver, for: Any do
  alias Absinthe.Adapter.LanguageConventions

  def resolve_type(%struct_name{} = data, resolution) do
    typename =
      struct_name
      |> Module.split()
      |> List.last()

    inner_resolve_type(data, typename, resolution)
  end

  def resolve_type(%{__typename: typename} = data, resolution) do
    inner_resolve_type(data, typename, resolution)
  end

  def resolve_type(%{"__typename" => typename} = data, resolution) do
    inner_resolve_type(data, typename, resolution)
  end

  defp inner_resolve_type(data, typename, resolution) do
    type = Absinthe.Schema.lookup_type(resolution.schema, typename)

    case type do
      %{resolve_type: resolve_type} when not is_nil(resolve_type) ->
        resolver = Absinthe.Type.function(type, :resolve_type)
        resolver.(data, resolution)

      _type ->
        to_internal_name(typename, resolution.adapter)
    end
  end
  end

  defp to_internal_name(name, adapter) when is_nil(adapter) do
    name
    |> LanguageConventions.to_internal_name(:type)
    |> String.to_existing_atom()
  end

  defp to_internal_name(name, adapter) when is_atom(adapter) do
    if adapter_has_to_internal_name_modifier?(adapter) do
      name
      |> adapter.to_internal_name(:type)
      |> String.to_existing_atom()
    else
      to_internal_name(name, nil)
    end
  end

  defp adapter_has_to_internal_name_modifier?(adapter) do
    Keyword.get(adapter.__info__(:functions), :to_internal_name) == 2
  end
end
