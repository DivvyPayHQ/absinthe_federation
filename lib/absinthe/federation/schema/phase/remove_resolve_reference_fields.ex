defmodule Absinthe.Federation.Schema.Phase.RemoveResolveReferenceFields do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint

  def run(%Blueprint{} = blueprint, _) do
    blueprint = Blueprint.postwalk(blueprint, &remove_resolve_reference_fields/1)
    {:ok, blueprint}
  end

  @spec remove_resolve_reference_fields(Blueprint.node_t()) :: Blueprint.node_t()
  defp remove_resolve_reference_fields(%{fields: fields} = node) when is_list(fields) do
    remove_field(node, :_resolve_reference)
  end

  defp remove_resolve_reference_fields(node), do: node

  defp remove_field(%{fields: fields} = node, field) when is_list(fields) and is_atom(field) do
    filtered_fields = Enum.reject(fields, &(&1.identifier == field))
    %{node | fields: filtered_fields}
  end
end
