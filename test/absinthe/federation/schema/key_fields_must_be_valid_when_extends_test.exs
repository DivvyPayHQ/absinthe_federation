defmodule Absinthe.Federation.Schema.KeyFieldsMustBeValidWhenExtendsTest do
  use ExUnit.Case, async: true

  @valid_schema """
    defmodule ValidSchemaWhenExtends do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :valid_product do
        extends()
        key_fields(["productUuid", "sku", "upc"])

        field :product_uuid, non_null(:id), do: external()
        field :sku, non_null(:string), do: external()
        field :upc, non_null(:string), do: external()
      end
    end
  """

  @flat_key_schema """
    defmodule FlatKeySchemaWhenExtends do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :product do
        extends()
        key_fields(["productUuid", "sku", "upc"])

        field :product_uuid, non_null(:id)
        field :sku, non_null(:string)
        field :upc, non_null(:string)
        field :color, non_null(:color)
      end

      object :color do
        field :id, non_null(:id)
        field :value, non_null(:string)
      end
    end
  """

  @nested_key_schema """
    defmodule NestedKeySchemaWhenExtends do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :product do
        extends()
        key_fields("color { productUuid }")

        field :sku, non_null(:string), do: external()
        field :upc, non_null(:string), do: external()
        field :color, non_null(:color)
      end

      object :color do
        field :product_uuid, non_null(:id)
        field :value, non_null(:string)
      end
    end
  """

  test "it should no error when key_fields valid" do
    assert {_, _} = Code.eval_string(@valid_schema)
  end

  test "it should throw an error when flat key fields is not marked @external" do
    assert %{phase_errors: [error3, error2, error1]} = catch_error(Code.eval_string(@flat_key_schema))
    assert %{message: "The field \"productUuid\" is not marked @external in :product object.\n"} = error1
    assert %{message: "The field \"sku\" is not marked @external in :product object.\n"} = error2
    assert %{message: "The field \"upc\" is not marked @external in :product object.\n"} = error3
  end

  test "it should throw an error when nested key field is not marked @external" do
    error = ~r/The field \"productUuid\" of @key \"color { productUuid }\" is not marked @external./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@nested_key_schema) end)
  end
end
