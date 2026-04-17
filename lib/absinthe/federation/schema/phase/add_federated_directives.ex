defmodule Absinthe.Federation.Schema.Phase.AddFederatedDirectives do
  @moduledoc false

  use Absinthe.Phase

  alias Absinthe.Blueprint
  alias Absinthe.Federation.Schema.Directive
  alias Absinthe.Type

  @dialyzer {:nowarn_function, prepend_directives: 2}

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

  # Directive specs: {meta_key, directive_name, kind}
  #   :flag        — only emit when meta value is `true`
  #   {:value, arg} — emit with a single named argument: [{arg, value}]
  #   :passthrough  — value is already a keyword list, pass directly
  @directive_specs [
    {:external, "external", :flag},
    {:requires_fields, "requires", {:value, :fields}},
    {:provides_fields, "provides", {:value, :fields}},
    {:extends, "extends", :flag},
    {:shareable, "shareable", :flag},
    {:override_from, "override", :passthrough},
    {:inaccessible, "inaccessible", :flag},
    {:interface_object, "interface_object", :flag},
    {:requires_scopes, "requires_scopes", {:value, :scopes}},
    {:policies, "policy", {:value, :policies}},
    {:authenticated, "authenticated", :flag},
    {:context, "context", {:value, :name}},
    {:list_size, "list_size", :passthrough},
    {:cost, "cost", {:value, :weight}}
  ]

  @spec maybe_add_directives(term(), any()) :: term()
  defp maybe_add_directives(node, meta) do
    adapter = Map.get(meta, :absinthe_adapter)

    directives =
      build_directives_from_specs(meta, adapter) ++
        build_key_directives(meta, adapter)

    case directives do
      [] -> node
      _ -> prepend_directives(node, directives)
    end
  end

  defp build_directives_from_specs(meta, adapter) do
    @directive_specs
    |> Enum.flat_map(&build_one(&1, meta, adapter))
    |> Enum.reverse()
  end

  defp build_one({meta_key, name, :flag}, meta, adapter) do
    if Map.get(meta, meta_key) == true,
      do: [Directive.build(name, adapter)],
      else: []
  end

  defp build_one({meta_key, name, {:value, arg}}, meta, adapter) do
    case Map.fetch(meta, meta_key) do
      {:ok, value} -> [Directive.build(name, adapter, [{arg, value}])]
      :error -> []
    end
  end

  defp build_one({meta_key, name, :passthrough}, meta, adapter) do
    case Map.fetch(meta, meta_key) do
      {:ok, args} -> [Directive.build(name, adapter, args)]
      :error -> []
    end
  end

  defp build_key_directives(%{key_fields: fields} = meta, _adapter) when is_binary(fields) do
    [Directive.build("key", Map.get(meta, :absinthe_adapter), fields: fields)]
  end

  defp build_key_directives(%{key_fields: fields} = meta, _adapter) when is_list(fields) do
    Enum.map(fields, &Directive.build("key", Map.get(meta, :absinthe_adapter), fields: &1))
  end

  defp build_key_directives(_meta, _adapter), do: []

  defp prepend_directives(%{directives: existing} = node, new_directives) do
    %{node | directives: new_directives ++ existing}
  end

  defp prepend_directives(node, _directives), do: node
end
