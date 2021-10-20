defmodule Absinthe.Federation.NotationTest do
  use Absinthe.Federation.Case, async: true

  describe "macro schema" do
    defmodule MacroSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :me, :user
      end

      object :user do
        key_fields("id")
        extends()

        field :id, non_null(:id) do
          external()
        end
      end

      extend object :product do
        key_fields("upc")

        external field :upc, non_null(:string)
      end
    end

    test "can use federation macros" do
      sdl = Absinthe.Schema.to_sdl(MacroSchema)
      assert sdl =~ "type User @extends @key(fields: \"id\")"
      assert sdl =~ "id: ID! @external"
      assert sdl =~ "type Product @extends @key(fields: \"upc\")"
      assert sdl =~ "upc: String! @external"
    end
  end
end
