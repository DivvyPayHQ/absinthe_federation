defmodule Absinthe.Federation.Schema.KeyFieldsMustBeValidTest do
  use Absinthe.Federation.Case, async: true

  @invalid_schema """
    defmodule FieldNotExistSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        extends()
      end

      object :dog do
        key_fields(["uuid"])
        field :id, non_null(:id)
      end
    end
  """

  @tag :impl
  test "it should throw an error" do
    error = ~r/The @key \"uuid\" is not exist in :dog object./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@invalid_schema) end)
  end
end
