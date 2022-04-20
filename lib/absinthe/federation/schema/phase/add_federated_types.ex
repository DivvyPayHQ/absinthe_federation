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
    blueprint
    |> add_types()
    |> maybe_remove_entities_field()
  end

  @spec add_types(Blueprint.t()) :: Blueprint.t()
  defp add_types(%Absinthe.Blueprint{} = blueprint) do
    Blueprint.postwalk(blueprint, &collect_types/1)
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

  @spec has_identifier?(Blueprint.node_t(), atom()) :: boolean()
  defp has_identifier?(node, identifier) when is_struct(node) and is_atom(identifier) do
    Map.get(node, :identifier) == identifier
  end

  defp has_identifier?(_node, _identifier) do
    false
  end

  @spec maybe_remove_entities_field(Blueprint.t()) :: {:ok, Blueprint.t()}
  defp maybe_remove_entities_field(blueprint) do
    blueprint
    |> Blueprint.find(&has_identifier?(&1, :_entity))
    |> case do
      %{types: []} -> {:ok, Blueprint.postwalk(blueprint, &remove_entities_field/1)}
      _ -> {:ok, blueprint}
    end
  end

  @spec remove_entities_field(Blueprint.node_t()) :: Blueprint.node_t()
  defp remove_entities_field(%{fields: fields} = node) when is_list(fields) do
    %{node | fields: Enum.reject(fields, &has_identifier?(&1, :_entities))}
  end

  defp remove_entities_field(node) do
    node
  end
end
