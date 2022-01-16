defmodule Absinthe.Federation.Schema.Schema.KeyFieldsMustBeValidWhenExtends do
  use ExUnit.Case, async: true

  @valid_schema """
    defmodule ValidSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :valid_product do
        extends()
        key_fields(["sku", "upc"])
        field :sku, non_null(:string), do: external()
        field :upc, non_null(:string), do: external()
      end
    end
  """

  @flat_key_schema """
    defmodule FlatKeySchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :product do
        extends()
        key_fields(["sku", "upc"])
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

  test "it should no error when key_fields valid" do
    assert {_, _} = Code.eval_string(@valid_schema)
  end

  test "it should throw an error when flat key fields not exist" do
    assert %{phase_errors: [error2, error1]} = catch_error(Code.eval_string(@flat_key_schema))
    assert %{message: "The @key \"sku\" does not mark as external in :product object.\n"} = error1
    assert %{message: "The @key \"upc\" does not mark as external in :product object.\n"} = error2
  end
end
