defmodule Absinthe.Federation.Schema.Phase.Validation.Util do
  def parse_key_fields(nested_key) do
    with {:ok, tokens} <- Absinthe.Lexer.tokenize("{ " <> nested_key <> " }"),
         {:ok, parsed} <- :absinthe_parser.parse(tokens) do
      access = [Access.key(:definitions), Access.at(0), Access.key(:selection_set), Access.key(:selections)]
      {:ok, get_in(parsed, access)}
    end
  end

  def is_nested?(key_fields) do
    String.contains?(key_fields, "{") and String.contains?(key_fields, "}")
  end

  def syntax_error(key, object) do
    %Absinthe.Phase.Error{
      message: "The @key #{inspect(key)} has a syntax error.",
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: %{key: key}
    }
  end

  def no_object_error(key, object, target_object) do
    %Absinthe.Phase.Error{
      message: "The object #{inspect(target_object)} of @key #{inspect(key)} does not exist.",
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: %{key: key}
    }
  end
end
