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
      end

      object :nested_product do
        key_fields("uuid variation { id }")
        field :upc, non_null(:string)
        field :sku, non_null(:string)
        field :variation, non_null(:product_variation)
      end
    end
  """

  test "it should throw an error when flat key fields not exist" do
    error =
      ~r/The @key \"name\" is not exist in :product object.(\w|\W|\s)+The @key \"uuid\" is not exist in :product object./

    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@flat_key_schema) end)
  end

  test "it should throw an error when nested key fields not exist in object" do
    error = ~r/The field \"uuid\" of @key \"uuid variation { id }\" is not exist./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@nested_key_schema) end)
  end

  @tag :impl
  test "it should throw an error when nested key fields not exist in schema" do
    error = ~r/The field \"uuid\" of @key \"uuid variation { id }\" is not exist./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@nested_ref_key_schema) end)
  end
end
