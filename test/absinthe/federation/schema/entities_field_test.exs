defmodule Absinthe.Federation.Schema.EntitiesFieldTest do
  use Absinthe.Federation.Case, async: true

  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.TypeReference.List
  alias Absinthe.Blueprint.TypeReference.Name
  alias Absinthe.Blueprint.TypeReference.NonNull

  alias Absinthe.Federation.Schema.EntitiesField

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
    end

    test "forwards call to correct resolver" do
      {:ok, %{}} = EntitiesField.resolver(%{}, %{}, %{schema: ResolverSchema})
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
