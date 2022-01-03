defmodule Absinthe.Federation.Schema.Phase.KeyFieldsMustBeValid do
  use Absinthe.Phase
  alias Absinthe.Blueprint

  @doc """
  Run validate
  """
  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &handle_schemas/1)
    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema) do
    schema = Blueprint.prewalk(schema, &validate_object/1)
    {:halt, schema}
  end

  defp handle_schemas(obj) do
    obj
  end

  defp validate_object(%Blueprint.Schema.ObjectTypeDefinition{} = object) do
    case get_in(object.__private__, [:meta, :key_fields]) do
      nil ->
        object

      key_fields ->
        validate_key_fields(key_fields, object)
    end
  end

  defp validate_object(obj) do
    obj
  end

  defp validate_key_fields(key_fields, object) when is_list(key_fields) do
    Enum.reduce(key_fields, object, fn x, acc -> validate_key_fields(x, acc) end)
  end

  defp validate_key_fields(key_fields, object) when is_binary(key_fields) do
    case String.split(key_fields) do
      [key_fields] ->
        if key_fields |> in?(object.fields) do
          object
        else
          Absinthe.Phase.put_error(object, error(key_fields, object))
        end

      [_ | _] ->
        nested_key_selections = key_fields |> parse_nested_key()
        Enum.reduce(nested_key_selections, object, fn x, acc -> validate_nested_key(x, acc, key_fields) end)
    end
  end

  defp validate_nested_key(%{selection_set: nil, name: key}, object, key_fields) do
    # when key in current schema
    if key |> in?(object.fields) do
      object
    else
      Absinthe.Phase.put_error(object, error(key, object, key_fields))
    end
  end

  defp validate_nested_key(selection, object, _key_fields) do
    bp = object.module.__absinthe_blueprint__()
    Absinthe.Blueprint.Schema.lookup_type(bp, String.to_atom(selection.name))
    object
  end

  defp in?(key, fields) do
    names = fields |> Enum.map(& &1.name)
    key in names
  end

  defp error(key, object) do
    %Absinthe.Phase.Error{
      message: explanation(key, object),
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: %{key: key}
    }
  end

  defp error(key, object, key_fields) do
    %Absinthe.Phase.Error{
      message: explanation(key, object, key_fields),
      locations: [object.__reference__.location],
      phase: __MODULE__,
      extra: %{key: key}
    }
  end

  defp parse_nested_key(nested_key) do
    with {:ok, tokens} <- Absinthe.Lexer.tokenize("{ " <> nested_key <> " }"),
         {:ok, parsed} <- :absinthe_parser.parse(tokens) do
      access = [Access.key(:definitions), Access.at(0), Access.key(:selection_set), Access.key(:selections)]
      get_in(parsed, access)
    end
  end

  def explanation(key, object) do
    """
    The @key #{inspect(key)} is not exist in #{inspect(object.identifier)} object.
    """
  end

  def explanation(field, _object, key_fields) do
    """
    The field #{inspect(field)} of @key #{inspect(key_fields)} is not exist.
    """
  end
end
