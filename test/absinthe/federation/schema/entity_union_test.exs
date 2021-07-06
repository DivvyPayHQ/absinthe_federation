defmodule Absinthe.Federation.Schema.EntityUnionTest do
  use Absinthe.Federation.Case, async: true

  alias Absinthe.Blueprint.Schema.UnionTypeDefinition

  alias Absinthe.Federation.Schema.EntityUnion

  describe "build" do
    defmodule EntityUnionSchema do
      use Absinthe.Schema

      query do
      end
    end

    setup do
      blueprint = EntityUnionSchema.__absinthe_blueprint__()
      {:ok, blueprint: blueprint}
    end

    test "builds union type definition", %{blueprint: blueprint} do
      assert %UnionTypeDefinition{} = EntityUnion.build(blueprint)
    end

    test "builds field definition with name", %{blueprint: blueprint} do
      union_type_definition = EntityUnion.build(blueprint)
      assert union_type_definition.name == "_Entity"
    end

    test "builds field definition with identifier", %{blueprint: blueprint} do
      union_type_definition = EntityUnion.build(blueprint)
      assert union_type_definition.identifier == :_entity
    end

    test "builds field definition with type", %{blueprint: blueprint} do
      union_type_definition = EntityUnion.build(blueprint)

      assert union_type_definition.types == []
    end
  end

  describe "sdl" do
    defmodule SDLSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      import_sdl """
      type Query {
        me: User
      }

      type User @key(fields: "id") {
        id: ID!
      }
      """
    end

    test "renders union correctly in sdl based schema" do
      sdl = Absinthe.Schema.to_sdl(SDLSchema)
      assert sdl =~ "union _Entity = User"
    end

    defmodule MacroSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :me, :user
      end

      object :user do
        key_fields("id")
        field :id, non_null(:id)
      end
    end

    test "renders union correctly in macro based schema" do
      sdl = Absinthe.Schema.to_sdl(MacroSchema)
      assert sdl =~ "union _Entity = User"
    end
  end
end
