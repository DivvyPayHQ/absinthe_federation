defmodule Absinthe.Federation.Schema.Phase.RemoveResolveReferenceFields do
  @moduledoc """
  Deletes `_resolve_reference` fields from the blueprint used to render the
  federated SDL (`_service { sdl }`, `to_federated_sdl/1`). That blueprint is
  discarded after rendering, so deleting the field is safe here.

  This is different than the `HideResolveReferenceFields` phase, which runs in
  the live compile-time pipeline and renames (never deletes) the field, since
  deleting it there would break `_entities` resolution.
  """

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
