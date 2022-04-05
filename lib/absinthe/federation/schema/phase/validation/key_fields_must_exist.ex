defmodule Absinthe.Federation.Schema.Phase.Validation.KeyFieldsMustExist do
  use Absinthe.Phase
  alias Absinthe.Blueprint
  import Absinthe.Federation.Schema.Phase.Validation.Util

  @doc """
  Run validate
  """
  def run(bp, _) do
    bp = Blueprint.prewalk(bp, &validate_object(&1, bp.adapter))
    {:ok, bp}
  end

  defp validate_object(%Blueprint.Schema.ObjectTypeDefinition{__private__: meta} = object, adapter) do
    case key_fields(object) do
      nil ->
        object

      key_fields ->
        validate_key_fields(key_fields, object, adapter)
    end
  end

  defp validate_object(obj, _), do: obj

  defp validate_key_fields(key_fields, object, adapter) when is_list(key_fields) do
    Enum.reduce(key_fields, object, fn x, acc -> validate_key_fields(x, acc) end)
  end

  defp validate_key_fields(key_fields, object, adapter) when is_binary(key_fields) do
    case is_nested?(key_fields) do
      true ->
        validate_nested_key_fields(key_fields, object, object)
      false ->
        if in?(key_fields, object.fields) do
          object
        else
          Absinthe.Phase.put_error(object, error(key_fields, object))
        end
    end
  end

  defp validate_nested_key_fields(key_fields, ancestor, object) when is_binary(key_fields) do
    case parse_key_fields(key_fields) do
      {:ok, nested_key_selections} ->
        validate_nested_key_fields(nested_key_selections, object, object, key_fields)
      _ ->
        Absinthe.Phase.put_error(object, syntax_error(key_fields, object))
    end
  end

  defp validate_nested_key_fields(selections, ancestor, object, key_fields) when is_list(selections) do
    Enum.reduce(selections, ancestor, fn x, acc -> validate_nested_key(x, acc, object, key_fields) end)
  end

  defp validate_nested_key_fields(%{selection_set: nil, name: key}, ancestor, object, key_fields) do
    if in?(key, object.fields) do
      ancestor
    else
      Absinthe.Phase.put_error(ancestor, error(key, ancestor, key_fields))
    end
  end

  defp validate_nested_key_fields(selection, ancestor, object, key_fields) do
    bp = ancestor.module.__absinthe_blueprint__()
    field = Enum.find(object.fields, fn x -> x.name == selection.name end)
    object = field && Absinthe.Blueprint.Schema.lookup_type(bp, field.type.of_type)

    if object do
      validate_nested_key(selection.selection_set.selections, ancestor, object, key_fields)
    else
      Absinthe.Phase.put_error(ancestor, no_object_error(key_fields, ancestor, selection.name))
    end
  end

  defp key_fields(object) do
    get_in(object.__private__, [:meta, :key_fields])
  end

  defp in?(key, fields) do
    Enum.any?(fields, &(key == &1.name))
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
    The @key #{inspect(key)} does not exist in #{inspect(object.identifier)} object.
    """
  end

  def explanation(field, _object, key_fields) do
    """
    The field #{inspect(field)} of @key #{inspect(key_fields)} does not exist.
    """
  end
end
