defmodule Absinthe.Federation.Schema.KeyFieldsMustBeValidTest do
  use Absinthe.Federation.Case, async: true

  @flat_key_schema """
    defmodule FlatKeySchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :product do
        key_fields(["uuid", "name"])
        field :id, non_null(:id)
      end
    end
  """

  @nested_key_schema """
    defmodule NestedKeySchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :product_variation do
        field :id, non_null(:id)
      end

      object :product do
        key_fields("uuid variation { id }")
        field :upc, non_null(:string)
        field :sku, non_null(:string)
        field :variation, non_null(:product_variation)
      end
    end
  """

  @nested_ref_key_schema """
    defmodule NestedRefKeySchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :product_variation do
        field :uuid, non_null(:id)
        field :change, non_null(:variation_change)
      end

      object :variation_change do
        field :name, :string
      end

      object :nested_product do
        # level 1: `:uuid`
        # level 2: `:id`
        # level 3: `:change_name`
        key_fields("uuid variation { id change { change_name } }")
        field :upc, non_null(:string)
        field :sku, non_null(:string)
        field :variation, non_null(:product_variation)
      end
    end
  """

  @invalid_syntax_schema """
  defmodule InvalidSyntaxSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()
    end

    object :product do
      key_fields("id { (variation id) } ")
      field :id, non_null(:id)
      field :variation, non_null(:product_variation)
    end

    object :product_variation do
      field :id, non_null(:id)
    end
  end
  """

  test "it should throw an error when flat key fields not exist" do
    assert %{phase_errors: [error2, error1]} = catch_error(Code.eval_string(@flat_key_schema))
    assert %{message: "The @key \"uuid\" does not exist in :product object.\n"} = error1
    assert %{message: "The @key \"name\" does not exist in :product object.\n"} = error2
  end

  test "it should throw an error when nested key fields not exist in object" do
    error = ~r/The field \"uuid\" of @key \"uuid variation { id }\" does not exist./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@nested_key_schema) end)
  end

  test "it should throw an error when nested key fields not exist in schema" do
    assert %{phase_errors: [error3, error2, error1]} = catch_error(Code.eval_string(@nested_ref_key_schema))

    assert %{message: "The field \"uuid\" of @key \"uuid variation { id change { change_name } }\" does not exist.\n"} =
             error1

    assert %{message: "The field \"id\" of @key \"uuid variation { id change { change_name } }\" does not exist.\n"} =
             error2

    assert %{
             message:
               "The field \"change_name\" of @key \"uuid variation { id change { change_name } }\" does not exist.\n"
           } = error3
  end

  test "it should throw an error when syntax error" do
    error = ~r/The @key \"id { \(variation id\) } \" has syntax error./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@invalid_syntax_schema) end)
  end
end
