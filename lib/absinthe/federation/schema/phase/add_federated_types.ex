defmodule Absinthe.Federation.Schema.Phase.AddFederatedTypes do
  @moduledoc """
  https://www.apollographql.com/docs/federation/federation-spec/#query_service

  The federation schema modifications (i.e. new types and directive definitions) should not be included in this SDL.
  """

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema
  alias Absinthe.Federation.Schema.EntitiesField
  alias Absinthe.Federation.Schema.EntityUnion
  alias Absinthe.Federation.Schema.ServiceField

  def run(%Blueprint{} = blueprint, _) do
    blueprint = Blueprint.postwalk(blueprint, &collect_types/1)
    {:ok, blueprint}
  end

  @spec collect_types(Blueprint.node_t()) :: Blueprint.node_t()
  defp collect_types(%Schema.SchemaDefinition{type_definitions: type_definitions} = node) do
    entity_union = EntityUnion.build(node)

    %{node | type_definitions: [entity_union | type_definitions]}
  end

  defp collect_types(%Schema.ObjectTypeDefinition{identifier: :query, fields: fields} = node) do
    service_field = ServiceField.build()
    entities_field = EntitiesField.build()
    %{node | fields: [service_field, entities_field] ++ fields}
  end

  defp collect_types(node), do: node
end
