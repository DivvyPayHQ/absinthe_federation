defmodule Absinthe.Federation.Schema.Phase.Validation.Util do
  alias Absinthe.Blueprint.TypeReference

  @wrappers [TypeReference.List, TypeReference.NonNull]

  def invalid_type_error(key, object, target_field, kind) do
    %Absinthe.Phase.Error{
      message:
        "The field #{inspect(target_field)} of @key #{inspect(key)} is #{kind} " <>
          "and cannot be part of a @key.",
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

  def parse_key_fields(nested_key) do
    with {:ok, tokens} <- Absinthe.Lexer.tokenize("{ " <> nested_key <> " }"),
         {:ok, parsed} <- :absinthe_parser.parse(tokens) do
      access = [Access.key(:definitions), Access.at(0), Access.key(:selection_set), Access.key(:selections)]
      {:ok, get_in(parsed, access)}
    end
  end

  def syntax_error(key, object) do
    %Absinthe.Phase.Error{
      message: "The @key #{inspect(key)} has a syntax error.",
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: %{key: key}
    }
  end

  @doc """
  Recursively strips non-null/list wrappers to reach the underlying type reference
  in order to turn an unexpected type reference into a validation error.
  """
  def unwrap_named_type(%TypeReference.Name{} = value), do: value
  def unwrap_named_type(%TypeReference.Identifier{} = value), do: value
  def unwrap_named_type(value) when is_atom(value), do: value
  def unwrap_named_type(%struct{of_type: inner}) when struct in @wrappers, do: unwrap_named_type(inner)
  def unwrap_named_type(other), do: other
end
