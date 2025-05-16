defmodule Absinthe.Federation.Schema.Directive do
  @moduledoc false

  alias Absinthe.Adapter.LanguageConventions
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Directive, as: BlueprintDirective
  alias Absinthe.Blueprint.Input.Argument
  alias Absinthe.Blueprint.Input.List
  alias Absinthe.Blueprint.Input.Boolean
  alias Absinthe.Blueprint.Input.Integer
  alias Absinthe.Blueprint.Input.RawValue
  alias Absinthe.Blueprint.Input.String
  alias Absinthe.Blueprint.SourceLocation
  alias Absinthe.Phase
  alias Absinthe.Schema.Notation

  # TODO: Fix __reference__ typespec upstream in absinthe
  @type directive :: %BlueprintDirective{
          name: binary(),
          arguments: [Blueprint.Input.Argument.t()],
          source_location: nil | Blueprint.SourceLocation.t(),
          schema_node: nil | Absinthe.Type.Directive.t(),
          flags: Blueprint.flags_t(),
          errors: [Phase.Error.t()],
          __reference__: nil | map(),
          __private__: []
        }

  @spec build(binary(), atom(), Keyword.t()) :: directive()
  def build(name, adapter, fields \\ [])

  def build(name, adapter, fields) when is_binary(name) and is_atom(adapter) and is_list(fields) do
    adapter = if is_nil(adapter), do: LanguageConventions, else: adapter

    %BlueprintDirective{
      __reference__: Notation.build_reference(__ENV__),
      name: to_external_name(name, adapter),
      arguments: build_arguments(name, adapter, fields)
    }
  end

  defp build_arguments(directive_name, adapter, fields) when is_list(fields) do
    fields
    |> Enum.map(fn {key, value} -> {key, maybe_convert_value_case(directive_name, key, value, adapter)} end)
    |> Enum.map(fn field -> build_argument(field, adapter) end)
  end

  defp build_argument({key, value}, adapter) when is_atom(key) do
    %Argument{
      name: to_external_name(key, adapter),
      input_value: %RawValue{
        content: build_value(value)
      },
      source_location: %SourceLocation{line: 0, column: 0}
    }
  end

  defp build_value(value) when is_list(value), do: %List{items: Enum.map(value, &build_value/1)}
  defp build_value(value) when is_binary(value), do: %String{value: value}
  defp build_value(value) when is_integer(value), do: %Integer{value: value}
  defp build_value(value) when is_boolean(value), do: %Boolean{value: value}

  defp to_external_name(key, adapter) when is_atom(key) do
    key
    |> Atom.to_string()
    |> to_external_name(adapter)
  end

  defp to_external_name(key, adapter) when is_binary(key) do
    if adapter_has_to_external_name_modifier?(adapter) do
      adapter.to_external_name(key, :directive)
    else
      key
    end
  end

  defp to_external_name(key, _adapter) do
    key
  end

  defp adapter_has_to_external_name_modifier?(adapter) do
    Keyword.get(adapter.__info__(:functions), :to_external_name) == 2
  end

  defp maybe_convert_value_case("key", :fields, value, adapter) when is_binary(value) do
    to_external_name(value, adapter)
  end

  defp maybe_convert_value_case("list_size", :sized_fields, values, adapter) when is_list(values) do
    Enum.map(values, fn value ->
      to_external_name(value, adapter)
    end)
  end

  defp maybe_convert_value_case(_directive_name, _key, value, _adapter) do
    value
  end
end
