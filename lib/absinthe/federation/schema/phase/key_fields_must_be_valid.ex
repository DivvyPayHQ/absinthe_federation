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
    if key_fields |> in?(object.fields) do
      object
    else
      Absinthe.Phase.put_error(object, error(key_fields, object))
    end
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

  def explanation(key, object) do
    """
    The @key #{inspect(key)} is not exist in #{inspect(object.identifier)} object.
    """
  end
end
