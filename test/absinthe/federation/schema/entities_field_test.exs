defmodule Absinthe.Federation.Schema.EntitiesFieldTest do
  use Absinthe.Federation.Case, async: true

  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.TypeReference.List
  alias Absinthe.Blueprint.TypeReference.Name
  alias Absinthe.Blueprint.TypeReference.NonNull

  alias Absinthe.Federation.Schema.EntitiesField

  import Absinthe.Resolution.Helpers, only: [async: 1]

  describe "build" do
    test "builds field definition" do
      assert %FieldDefinition{} = EntitiesField.build()
    end

    test "builds field definition with name" do
      field_definition = EntitiesField.build()
      assert field_definition.name == "_entities"
    end

    test "builds field definition with identifier" do
      field_definition = EntitiesField.build()
      assert field_definition.identifier == :_entities
    end

    test "builds field definition with type" do
      field_definition = EntitiesField.build()

      assert %NonNull{
               of_type: %List{
                 of_type: %Name{
                   name: "_Entity"
                 }
               }
             } = field_definition.type
    end

    test "builds field definition with middleware" do
      field_definition = EntitiesField.build()
      assert Enum.count(field_definition.middleware) == 1
    end
  end

  describe "resolver" do
    defmodule ResolverSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :test, :string
      end

      object :product do
        key_fields("upc")
        field :upc, non_null(:string)
        field :apa, non_null(:string), resolve: fn _, _, _ -> {:ok, "BANANA"} end

        field :_resolve_reference, :product do
          resolve(fn _, args, _ ->
            async(fn _ ->
              {:ok, args}
            end)
          end)
        end
      end
    end

    test "resolves all types fulfilling the _Entity type" do
      query = """
        query{
          _entities(representations:[
            {
              __typename: "Product",
              upc: "123"
            },
            {
              __typename: "Product",
              upc: "456"
            }
            ]){
              ...on Product{
                upc
                apa
              }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, ResolverSchema, variables: %{})

      assert %{data: %{"_entities" => [%{"upc" => "123", "apa" => "BANANA"}, %{"apa" => "BANANA", "upc" => "456"}]}} =
               resp
    end
  end

  describe "sdl" do
    defmodule SDLSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :test, :string
      end
    end

    test "renders correctly in sdl" do
      sdl = Absinthe.Schema.to_sdl(SDLSchema)
      assert sdl =~ "_entities(representations: [_Any!]!): [_Entity]!"
    end
  end
end
