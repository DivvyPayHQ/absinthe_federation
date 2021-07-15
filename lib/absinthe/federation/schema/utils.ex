defmodule Absinthe.Federation.Schema.Utils do
  @moduledoc false

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.TypeReference.Name
  alias Absinthe.Type

  @spec key_field_types(Blueprint.t()) :: list(Blueprint.node_t())
  def key_field_types(blueprint) do
    {_blueprint, types} = Blueprint.postwalk(blueprint, [], &collect_key_field_types/2)

    types
  end

  defp collect_key_field_types(
         %{name: name, __private__: _private} = node,
         types
       ) do
    if has_key_directive?(node) do
      {node, [%Name{name: name} | types]}
    else
      {node, types}
    end
  end

  defp collect_key_field_types(node, types), do: {node, types}

  @spec has_key_directive?(struct()) :: boolean()
  def has_key_directive?(node) do
    meta = Type.meta(node)
    has_meta_key = Map.has_key?(meta, :key_fields)
    node_directives = Map.get(node, :directives, [])
    has_key_directive = Enum.any?(node_directives, &is_key_directive?/1)
    has_meta_key or has_key_directive
  end

  @spec is_key_directive?(Blueprint.Directive.t()) :: boolean()
  def is_key_directive?(%{name: "key"} = _directive), do: true
  def is_key_directive?(_directive), do: false
end
