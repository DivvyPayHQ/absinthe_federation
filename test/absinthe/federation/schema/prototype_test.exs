defmodule Absinthe.Federation.Schema.PrototypeTest do
  use Absinthe.Federation.Case, async: true

  describe "import_sdl" do
    defmodule SDLSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      import_sdl """
      type Query {
        me: User
      }

      type User @extends @key(fields: "id") {
        id: ID! @external
        name: String
      }

      union _Entity = User
      """
    end

    test "can use federation directives" do
      sdl = Absinthe.Schema.to_sdl(SDLSchema)

      assert sdl =~ "type User @extends @key(fields: \"id\")"
      assert sdl =~ "id: ID! @external"
    end
  end
end
