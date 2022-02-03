defmodule Absinthe.Federation.Schema.Phase.Validation.KeyFieldsMustBeValidWhenExtends do
  use Absinthe.Phase
  alias Absinthe.Blueprint
  import Absinthe.Federation.Schema.Phase.Validation.Util

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
    case is_extending?(object) do
      false ->
        object

      true ->
        key_fields = get_in(object.__private__, [:meta, :key_fields])
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
    case is_nested?(key_fields) do
      false ->
        if key_fields |> is_marked_as_external?(object.fields) do
          object
        else
          Absinthe.Phase.put_error(object, error(key_fields, object))
        end

      true ->
        {:ok, nested_key_selections} = parse_key_fields(key_fields)
        validate_nested_key(nested_key_selections, object, object, key_fields)
    end
  end

  defp validate_nested_key(selections, ancestor, object, key_fields) when is_list(selections) do
    Enum.reduce(selections, ancestor, fn x, acc -> validate_nested_key(x, acc, object, key_fields) end)
  end

  defp validate_nested_key(%{selection_set: nil, name: key}, ancestor, object, key_fields) do
    if key |> is_marked_as_external?(object.fields) do
      ancestor
    else
      Absinthe.Phase.put_error(ancestor, error(key, ancestor, key_fields))
    end
  end

  defp validate_nested_key(selection, ancestor, object, key_fields) do
    bp = ancestor.module.__absinthe_blueprint__()
    field = Enum.find(object.fields, fn x -> x.name == selection.name end)
    object = Absinthe.Blueprint.Schema.lookup_type(bp, field.type.of_type)
    validate_nested_key(selection.selection_set.selections, ancestor, object, key_fields)
  end

  defp is_extending?(object) do
    not is_nil(get_in(object.__private__, [:meta, :key_fields])) and
      not is_nil(get_in(object.__private__, [:meta, :extends]))
  end

  defp is_marked_as_external?(key, fields) do
    field = Enum.find(fields, &(key == &1.name))
    field.directives != [] && has_external?(field)
  end

  defp has_external?(field) do
    Enum.find(field.directives, fn x -> x.name == "external" end)
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

  def explanation(key, object) do
    """
    The field #{inspect(key)} is not marked @external in #{inspect(object.identifier)} object.
    """
  end

  def explanation(field, _object, key_fields) do
    """
    The field #{inspect(field)} of @key #{inspect(key_fields)} is not marked @external.
    """
  end
end
