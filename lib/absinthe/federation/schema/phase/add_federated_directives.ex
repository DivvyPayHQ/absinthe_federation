defmodule Absinthe.Federation.Schema.Phase.AddFederatedDirectives do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Federation.Schema.Directive
  alias Absinthe.Type

  @dialyzer {:nowarn_function, add_directive: 2}

  def run(%Blueprint{} = blueprint, _) do
    adapter = Map.get(blueprint, :adapter, LanguageConventions)
    blueprint = Blueprint.postwalk(blueprint, &collect_types(&1, adapter))
    {:ok, blueprint}
  end

  defp collect_types(%{__private__: _private} = node, adapter) do
    meta = node |> Type.meta() |> Map.put_new(:absinthe_adapter, adapter)
    maybe_add_directives(node, meta)
  end

  defp collect_types(node, _adapter), do: node

  @spec maybe_add_directives(term(), any()) :: term()
  defp maybe_add_directives(node, meta) do
    node
    |> maybe_add_key_directive(meta)
    |> maybe_add_external_directive(meta)
    |> maybe_add_requires_directive(meta)
    |> maybe_add_provides_directive(meta)
    |> maybe_add_extends_directive(meta)
    |> maybe_add_shareable_directive(meta)
    |> maybe_add_override_directive(meta)
    |> maybe_add_inaccessible_directive(meta)
    |> maybe_add_interface_object_directive(meta)
    |> maybe_add_tag_directive(meta)
  end

  @spec maybe_add_key_directive(term(), map()) :: term()
  defp maybe_add_key_directive(node, %{key_fields: fields, absinthe_adapter: adapter}) when is_binary(fields) do
    directive = Directive.build("key", adapter, fields: fields)

    add_directive(node, directive)
  end

  defp maybe_add_key_directive(node, %{key_fields: fields, absinthe_adapter: adapter}) when is_list(fields) do
    fields
    |> Enum.map(&Directive.build("key", adapter, fields: &1))
    |> Enum.reduce(node, &add_directive(&2, &1))
  end

  defp maybe_add_key_directive(node, _meta), do: node

  defp maybe_add_external_directive(node, %{external: true, absinthe_adapter: adapter}) do
    directive = Directive.build("external", adapter)

    add_directive(node, directive)
  end

  defp maybe_add_external_directive(node, _meta), do: node

  defp maybe_add_requires_directive(node, %{requires_fields: fields, absinthe_adapter: adapter}) do
    directive = Directive.build("requires", adapter, fields: fields)

    add_directive(node, directive)
  end

  defp maybe_add_requires_directive(node, _meta), do: node

  defp maybe_add_provides_directive(node, %{provides_fields: fields, absinthe_adapter: adapter}) do
    directive = Directive.build("provides", adapter, fields: fields)

    add_directive(node, directive)
  end

  defp maybe_add_provides_directive(node, _meta), do: node

  defp maybe_add_extends_directive(node, %{extends: true, absinthe_adapter: adapter}) do
    directive = Directive.build("extends", adapter)

    add_directive(node, directive)
  end

  defp maybe_add_extends_directive(node, _meta), do: node

  defp maybe_add_shareable_directive(node, %{shareable: true, absinthe_adapter: adapter}) do
    directive = Directive.build("shareable", adapter)

    add_directive(node, directive)
  end

  defp maybe_add_shareable_directive(node, _meta), do: node

  defp maybe_add_override_directive(node, %{override_from: subgraph, absinthe_adapter: adapter}) do
    directive = Directive.build("override", adapter, from: subgraph)

    add_directive(node, directive)
  end

  defp maybe_add_override_directive(node, _meta), do: node

  defp maybe_add_inaccessible_directive(node, %{inaccessible: true, absinthe_adapter: adapter}) do
    directive = Directive.build("inaccessible", adapter)

    add_directive(node, directive)
  end

  defp maybe_add_inaccessible_directive(node, _meta), do: node

  defp maybe_add_interface_object_directive(node, %{interface_object: true, absinthe_adapter: adapter}) do
    directive = Directive.build("interface_object", adapter)

    add_directive(node, directive)
  end

  defp maybe_add_interface_object_directive(node, _meta), do: node

  defp maybe_add_tag_directive(node, %{tag: name, absinthe_adapter: adapter}) do
    directive = Directive.build("tag", adapter, name: name)

    add_directive(node, directive)
  end

  defp maybe_add_tag_directive(node, _meta), do: node

  defp add_directive(%{directives: directives} = node, directive) do
    %{node | directives: [directive | directives]}
  end

  defp add_directive(node, _directive), do: node
end
