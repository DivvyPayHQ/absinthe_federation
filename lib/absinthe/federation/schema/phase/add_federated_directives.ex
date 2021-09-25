defmodule Absinthe.Federation.Schema.Phase.AddFederatedDirectives do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Federation.Schema.Directive
  alias Absinthe.Type

  @dialyzer {:nowarn_function, add_directive: 2}

  def run(%Blueprint{} = blueprint, _) do
    blueprint = Blueprint.postwalk(blueprint, &collect_types/1)
    {:ok, blueprint}
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
  defp maybe_add_key_directive(node, %{key_fields: fields}) when is_binary(fields) do
    directive = Directive.build("key", fields: fields)

    add_directive(node, directive)
  end

  defp maybe_add_key_directive(node, %{key_fields: fields}) when is_list(fields) do
    fields
    |> Enum.map(&Directive.build("key", fields: &1))
    |> Enum.reduce(node, &add_directive(&2, &1))
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
