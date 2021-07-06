defmodule Absinthe.Federation.Schema.Phase do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Schema
  alias Absinthe.Federation.Schema.Directive
  alias Absinthe.Federation.Schema.EntitiesField
  alias Absinthe.Federation.Schema.EntityUnion
  alias Absinthe.Federation.Schema.ServiceField
  alias Absinthe.Type

  @dialyzer {:nowarn_function, add_directive: 2}

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

  defp collect_types(%{__private__: _private} = node) do
    meta = Type.meta(node)
    maybe_add_directives(node, meta)
  end

  defp collect_types(node), do: node

  @spec maybe_add_directives(term(), any()) :: term()
  defp maybe_add_directives(node, meta) do
    node
    |> maybe_add_key_directive(meta)
    |> maybe_add_external_directive(meta)
    |> maybe_add_requires_directive(meta)
    |> maybe_add_provides_directive(meta)
    |> maybe_add_extends_directive(meta)
  end

  @spec maybe_add_key_directive(term(), map()) :: term()
  defp maybe_add_key_directive(node, %{key_fields: fields}) do
    directive = Directive.build("key", fields: fields)

    add_directive(node, directive)
  end

  defp maybe_add_key_directive(node, _meta), do: node

  defp maybe_add_external_directive(node, %{external: true}) do
    directive = Directive.build("external")

    add_directive(node, directive)
  end

  defp maybe_add_external_directive(node, _meta), do: node

  defp maybe_add_requires_directive(node, %{requires_fields: fields}) do
    directive = Directive.build("requires", fields: fields)

    add_directive(node, directive)
  end

  defp maybe_add_requires_directive(node, _meta), do: node

  defp maybe_add_provides_directive(node, %{provides_fields: fields}) do
    directive = Directive.build("provides", fields: fields)

    add_directive(node, directive)
  end

  defp maybe_add_provides_directive(node, _meta), do: node

  defp maybe_add_extends_directive(node, %{extends: true}) do
    directive = Directive.build("extends")

    add_directive(node, directive)
  end

  defp maybe_add_extends_directive(node, _meta), do: node

  defp add_directive(%{directives: directives} = node, directive) do
    %{node | directives: [directive | directives]}
  end

  defp add_directive(node, _directive), do: node
end
