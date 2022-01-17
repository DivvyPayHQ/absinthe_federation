defmodule Absinthe.Federation.Schema.Phase.Validation.Util do
  def parse_key_fields(nested_key) do
    with {:ok, tokens} <- Absinthe.Lexer.tokenize("{ " <> nested_key <> " }"),
         {:ok, parsed} <- :absinthe_parser.parse(tokens) do
      access = [Access.key(:definitions), Access.at(0), Access.key(:selection_set), Access.key(:selections)]
      {:ok, get_in(parsed, access)}
    end
  end

  def syntax_error(key, object) do
    %Absinthe.Phase.Error{
      message: "The @key #{inspect(key)} has syntax error.",
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: %{key: key}
    }
  end
end
