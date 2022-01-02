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

      object :product_variation do
          field :id, non_null(:id)
      end

      object :product do
        key_fields(["upc", "sku variation { id }"])
        field :upc, non_null(:string)
        field :sku, non_null(:string)
        field :variation, non_null(:product_variation)
      end
    end
  """

  test "it should throw an error when flat key fields not exist" do
    error = ~r/The @key \"name\" is not exist in :product object./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@flat_key_schema) end)
  end

  test "it should throw an error when nested key fields not exist" do
    error = ~r/The @key \"name\" is not exist in :product object./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@nested_key_schema) end)
  end
end
