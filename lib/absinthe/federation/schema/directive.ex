defmodule Absinthe.Federation.Schema.Directive do
  @moduledoc false

  alias Absinthe.Adapter.LanguageConventions
  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Directive, as: BlueprintDirective
  alias Absinthe.Blueprint.Input.Argument
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

  defp build_arguments("key", adapter, fields) when is_list(fields) do
    fields
    |> Enum.map(fn {key, value} -> {key, to_external_name(value, adapter)} end)
    |> Enum.map(&build_argument/1)
  end

  defp build_arguments(_name, _adapter, fields) when is_list(fields) do
    Enum.map(fields, &build_argument/1)
  end

  defp build_argument({key, value}) when is_atom(key) and is_binary(value) do
    %Argument{
      name: Atom.to_string(key),
      input_value: %RawValue{
        content: %String{
          value: value
        }
      },
      source_location: %SourceLocation{line: 0, column: 0}
    }
  end

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

  defp adapter_has_to_external_name_modifier?(adapter) do
    Keyword.get(adapter.__info__(:functions), :to_external_name) == 2
  end
end
