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

  @spec build(binary(), Keyword.t()) :: directive()
  def build(name, fields \\ [])

  def build(name, fields) when is_binary(name) and is_list(fields) do
    %BlueprintDirective{
      __reference__: Notation.build_reference(__ENV__),
      name: to_external_name(name),
      arguments: build_arguments(name, fields)
    }
  end

  defp build_arguments("key", fields) when is_list(fields) do
    fields
    |> Enum.map(fn {key, value} -> {key, to_external_name(value)} end)
    |> Enum.map(&build_argument/1)
  end

  defp build_arguments(_name, fields) when is_list(fields) do
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

  defp to_external_name(key) when is_atom(key) do
    key
    |> Atom.to_string()
    |> to_external_name
  end

  defp to_external_name(key) when is_binary(key) do
    LanguageConventions.to_external_name(key, :directive)
  end
end
