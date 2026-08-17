defmodule Absinthe.Federation.Schema.Phase.HideResolveReferenceFields do
  @moduledoc """
  Hides the `_resolve_reference` field from introspection without removing it
  from the schema. Absinthe's introspection resolver excludes any field whose
  `name` starts with two leading underscores
  (see `Absinthe.Type.introspection?/1`), so renaming (rather than deleting)
  the field keeps entity resolution working (`entities_field.ex` looks the
  field up by `identifier`, not `name`) while hiding it from `__schema`/`__type`
  introspection and direct queries.

  A `__`-prefixed name is normally rejected by
  `Absinthe.Phase.Schema.Validation.TypeNamesAreReserved`. That phase exposes
  `allow_reserved/1` for exactly this case (built-in introspection types use the
  same escape hatch), so this phase can run anywhere in the pipeline instead of
  being anchored relative to the validator.

  This is different than the `RemoveResolveReferenceFields` phase, which deletes
  (not renames) the field from the disposable blueprint used only for SDL
  rendering.
  """

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Phase.Schema.Validation.TypeNamesAreReserved

  @hidden_name "__resolve_reference"

  def run(%Blueprint{} = blueprint, _) do
    blueprint = Blueprint.postwalk(blueprint, &hide_resolve_reference_fields/1)
    {:ok, blueprint}
  end

  @spec hide_resolve_reference_fields(Blueprint.node_t()) :: Blueprint.node_t()
  defp hide_resolve_reference_fields(%{fields: fields} = node) when is_list(fields) do
    %{node | fields: Enum.map(fields, &hide_field/1)}
  end

  defp hide_resolve_reference_fields(node), do: node

  defp hide_field(%{identifier: :_resolve_reference} = field) do
    %{field | name: @hidden_name}
    |> TypeNamesAreReserved.allow_reserved()
  end

  defp hide_field(field), do: field
end
