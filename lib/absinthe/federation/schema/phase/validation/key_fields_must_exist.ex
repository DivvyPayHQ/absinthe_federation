defmodule Absinthe.Federation.Schema.Phase.Validation.KeyFieldsMustExist do
  use Absinthe.Phase
  alias Absinthe.Blueprint
  import Absinthe.Federation.Schema.Phase.Validation.Util

  @doc """
  Run validate
  """
  def run(bp, _) do
    adapter = bp.adapter || Absinthe.Adapter.LanguageConventions
    bp = Blueprint.prewalk(bp, &handle_schemas(&1, adapter, bp))
    {:ok, bp}
  end

  defp handle_schemas(%Blueprint.Schema.SchemaDefinition{} = schema, adapter, bp) do
    schema = Blueprint.prewalk(schema, &validate_object(&1, adapter, bp))
    {:halt, schema}
  end

  defp handle_schemas(obj, _adapter, _bp) do
    obj
  end

  defp validate_object(%Blueprint.Schema.ObjectTypeDefinition{} = object, adapter, bp) do
    case is_defining_or_extending?(object) do
      false ->
        object

      true ->
        key_fields = get_in(object.__private__, [:meta, :key_fields])
        validate_key_fields(key_fields, object, adapter, bp)
    end
  end

  defp validate_object(obj, _adapter, _bp) do
    obj
  end

  defp validate_key_fields(key_fields, object, adapter, bp) when is_list(key_fields) do
    Enum.reduce(key_fields, object, fn x, acc -> validate_key_fields(x, acc, adapter, bp) end)
  end

  defp validate_key_fields(key_fields, object, adapter, bp) when is_binary(key_fields) do
    # A key fieldset is always parsed as a selection set, so that a single field ("sku"), a
    # compound key ("sku package") and a nested key ("sku variation { id }") are all handled the
    # same way. Leaf selections are checked against the object's fields; selections with a
    # sub-selection recurse into the referenced type.
    case parse_key_fields(key_fields) do
      {:ok, [%{selection_set: nil, name: key}]} ->
        if in?(key, object.fields, adapter) do
          object
        else
          Absinthe.Phase.put_error(object, error(key, object))
        end

      {:ok, key_selections} ->
        validate_nested_key(key_selections, object, object, key_fields, adapter, bp)

      _error ->
        Absinthe.Phase.put_error(object, syntax_error(key_fields, object))
    end
  end

  defp validate_nested_key(selections, ancestor, object, key_fields, adapter, bp) when is_list(selections) do
    Enum.reduce(selections, ancestor, fn x, acc -> validate_nested_key(x, acc, object, key_fields, adapter, bp) end)
  end

  defp validate_nested_key(%{selection_set: nil, name: key}, ancestor, object, key_fields, adapter, _bp) do
    if key |> in?(object.fields, adapter) do
      ancestor
    else
      Absinthe.Phase.put_error(ancestor, error(key, ancestor, key_fields))
    end
  end

  defp validate_nested_key(selection, ancestor, object, key_fields, adapter, bp) do
    internal_name = adapter.to_internal_name(selection.name, :field)
    field = Enum.find(object.fields, fn x -> x.name == internal_name end)

    cond do
      is_nil(field) ->
        Absinthe.Phase.put_error(ancestor, no_object_error(key_fields, ancestor, selection.name))

      true ->
        case Absinthe.Blueprint.Schema.lookup_type(bp, unwrap_named_type(field.type)) do
          %Blueprint.Schema.ObjectTypeDefinition{} = nested ->
            validate_nested_key(selection.selection_set.selections, ancestor, nested, key_fields, adapter, bp)

          %Blueprint.Schema.InterfaceTypeDefinition{} ->
            Absinthe.Phase.put_error(
              ancestor,
              invalid_type_error(key_fields, ancestor, selection.name, "an interface type")
            )

          %Blueprint.Schema.UnionTypeDefinition{} ->
            Absinthe.Phase.put_error(
              ancestor,
              invalid_type_error(key_fields, ancestor, selection.name, "a union type")
            )

          _other_type ->
            Absinthe.Phase.put_error(ancestor, no_object_error(key_fields, ancestor, selection.name))
        end
    end
  end

  defp is_defining_or_extending?(object) do
    not is_nil(get_in(object.__private__, [:meta, :key_fields]))
  end

  defp in?(key, fields, adapter) do
    internal_key = adapter.to_internal_name(key, :field)
    Enum.any?(fields, &(internal_key == &1.name))
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
