defmodule Absinthe.Federation.Schema.EntityUnionTest do
  use Absinthe.Federation.Case, async: true

  alias Absinthe.Blueprint.Schema.UnionTypeDefinition

  alias Absinthe.Federation.Schema.EntityUnion

  describe "build" do
    defmodule EntityUnionSchema do
      use Absinthe.Schema

      query do
        field :me, :string
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

      query do
      end

      object :credit_application do
        key_fields("id")
        field :id, :string

        field :_resolve_reference, :credit_application do
          resolve(fn _, %{id: id} = args, _ ->
            case id do
              "123" -> {:ok, args}
              _ -> {:error, "ID doesn't exist #{id}"}
            end
          end)
        end
      end

      object :product do
        key_fields("upc")
        field :upc, :string

        field :_resolve_reference, :product do
          resolve(fn _, args, _ -> {:ok, args} end)
        end
      end

      object :spec_item do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :spec_item do
          resolve(fn _, %{item_id: item_id}, _ -> {:ok, %SpecItem{item_id: item_id}} end)
        end
      end
    end

    test "correct object type returned" do
      query = """
        {
          _entities(representations: [{__typename: "CreditApplication", id: "123"}, {__typename: "Product", upc: "321"}, {__typename: "SpecItem", item_id: "456"}, {__typename: "SpecItem", item_id: "456"}]) {
            ...on CreditApplication {
              id
            }
            ...on Product {
              upc
            }
            ...on SpecItem {
              itemId
            }
          }
        }
      """

      %{data: %{"_entities" => [credit_app, product, spec_item, spec_item_two]}} =
        Absinthe.run!(query, ResolveTypeSchema)

      assert credit_app == %{"id" => "123"}
      assert product == %{"upc" => "321"}
      assert spec_item == %{"itemId" => "456"}
      assert spec_item_two == %{"itemId" => "456"}
    end

    test "error handling" do
      query = """
        {
          _entities(representations: [{__typename: "CreditApplication", id: "1"}, {__typename: "Product", upc: "321"}, {__typename: "SpecItem", item_id: "456"}]) {
            ...on CreditApplication {
              id
            }
          }
        }
      """

      assert %{
               data: nil,
               errors: [%{locations: [%{column: 5, line: 2}], message: "ID doesn't exist 1", path: ["_entities"]}]
             } = Absinthe.run!(query, ResolveTypeSchema)
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

    defmodule MacroSchemaWithNoTypesForUnionEntity do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :foo, :string
      end
    end

    test "omitted from the sdl if there are no types for union _Entity in macro based schema" do
      sdl = Absinthe.Schema.to_sdl(MacroSchemaWithNoTypesForUnionEntity)
      refute sdl =~ "union _Entity"
    end

    defmodule SDLSchemaNoTypesForUnionEntity do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      import_sdl """
      type Query {
        foo: Boolean
      }
      """
    end

    test "omitted from the sdl if there are no types for union _Entity in sdl based schema" do
      sdl = Absinthe.Schema.to_sdl(SDLSchemaNoTypesForUnionEntity)
      refute sdl =~ "union _Entity"
    end

    defmodule MacroSchemaWithInterface do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :shapes, list_of(:shape)
      end

      interface :shape do
        key_fields("id")
        field :id, non_null(:id)
      end

      object :circle do
        key_fields("id")
        field :id, non_null(:id)
      end

      object :rectangle do
        key_fields("id")
        field :id, non_null(:id)
      end
    end

    test "omits interfaces with keys from the entities union" do
      sdl = Absinthe.Schema.to_sdl(MacroSchemaWithInterface)
      assert sdl =~ "union _Entity = Circle | Rectangle"
    end
  end
end
