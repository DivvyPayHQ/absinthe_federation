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

  describe "resolve_type" do
    defmodule ResolveTypeSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      entity do
        types [:credit_application, :product]

        resolve_type fn
          %{upc: _}, _ -> :product
          _, _ -> :credit_application
        end
      end

      query do
      end

      object :credit_application do
        key_fields("id")
        field :id, :string

        field :_resolve_reference, :credit_application do
          resolve(fn _, args, _ -> {:ok, args} end)
        end
      end

      object :product do
        key_fields("upc")
        field :upc, :string

        field :_resolve_reference, :product do
          resolve(fn _, args, _ -> {:ok, args} end)
        end
      end
    end

    test "correct object type returned" do
      query = """
        {
          _entities(representations: [{__typename: "CreditApplication", id: "123"}, {__typename: "Product", upc: "321"}]) {
            ...on CreditApplication {
              id
            }
            ...on Product {
              upc
            }
          }
        }
      """

      %{data: %{"_entities" => [credit_app, product]}} = Absinthe.run!(query, ResolveTypeSchema)
      assert credit_app == %{"id" => "123"}
      assert product == %{"upc" => "321"}
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

      union _Entity = User
      """
    end

    test "renders union correctly in sdl based schema" do
      sdl = Absinthe.Schema.to_sdl(SDLSchema)
      assert sdl =~ "union _Entity = User"
    end

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
        field :id, non_null(:id)
      end
    end

    test "renders union correctly in macro based schema" do
      sdl = Absinthe.Schema.to_sdl(MacroSchema)
      assert sdl =~ "union _Entity = User"
    end
  end

  describe "entity macro" do
    defmodule UserEntity do
      defstruct [:id]
    end

    defmodule EntitySchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      entity do
        types [:user]
        resolve_type fn %UserEntity{}, _ -> :user end
      end

      query do
        field :me, :user
      end

      object :user do
        key_fields("id")
        field :id, non_null(:id)

        field :_resolve_reference, :user do
          resolve(fn _, %{id: id}, _ -> {:ok, %UserEntity{id: id}} end)
        end
      end
    end

    test "works" do
      query = """
        {
          _entities(representations: [{__typename: "User", id: "123"}]) {
            ...on User {
              id
            }
          }
        }
      """

      assert %{data: %{"_entities" => [%{"id" => "123"}]}} = Absinthe.run!(query, EntitySchema)
    end
  end
end
