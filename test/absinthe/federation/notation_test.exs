defmodule Absinthe.Federation.NotationTest do
  use Absinthe.Federation.Case, async: true

  describe "macro schema" do
    defmodule MacroSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      entity do
        types [:user]
        resolve_type fn _, _ -> :user end
      end

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
    end

    test "can use federation macros" do
      sdl = Absinthe.Schema.to_sdl(MacroSchema)
      assert sdl =~ "type User @extends @key(fields: \"id\")"
      assert sdl =~ "id: ID! @external"
    end
  end
end
