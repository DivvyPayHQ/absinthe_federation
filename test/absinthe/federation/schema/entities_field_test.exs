defmodule Absinthe.Federation.Schema.EntitiesFieldTest do
  use Absinthe.Federation.Case, async: true

  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.TypeReference.List
  alias Absinthe.Blueprint.TypeReference.Name
  alias Absinthe.Blueprint.TypeReference.NonNull

  alias Absinthe.Federation.Schema.EntitiesField

  defmodule EntitiesSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
    end

    object :foo do
      key_fields("id")
      field :id, :id
    end
  end

  setup do
    {:ok, blueprint: EntitiesSchema.__absinthe_blueprint__()}
  end

  describe "build" do
    test "builds field definition", %{blueprint: blueprint} do
      assert %FieldDefinition{} = EntitiesField.build(blueprint)
    end

    test "builds field definition with name", %{blueprint: blueprint} do
      field_definition = EntitiesField.build(blueprint)
      assert field_definition.name == "_entities"
    end

    test "builds field definition with identifier", %{blueprint: blueprint} do
      field_definition = EntitiesField.build(blueprint)
      assert field_definition.identifier == :_entities
    end

    test "builds field definition with type", %{blueprint: blueprint} do
      field_definition = EntitiesField.build(blueprint)

      assert %NonNull{
               of_type: %List{
                 of_type: %Name{
                   name: "_Entity"
                 }
               }
             } = field_definition.type
    end

    test "builds field definition with middleware", %{blueprint: blueprint} do
      field_definition = EntitiesField.build(blueprint)
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
        field :upc, non_null(:string)

        field :_resolve_reference, :product do
          resolve(fn _, args, _ -> {:ok, args} end)
        end
      end
    end

    test "forwards call to correct resolver" do
      upc = "123"
      representation = %{"__typename" => "Product", "upc" => upc}

      {:ok, [args]} =
        EntitiesField.resolver(%{}, %{representations: [representation]}, %{
          schema: ResolverSchema
        })

      assert args == %{__typename: "Product", upc: upc}
    end
  end

  describe "sdl" do
    defmodule SDLWithKeyFieldsSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :user, :user
      end

      object :user do
        key_fields("id")
        field :id, non_null(:id)
      end
    end

    test "renders correctly in sdl with @key" do
      sdl = Absinthe.Schema.to_sdl(SDLWithKeyFieldsSchema)
      assert sdl =~ "_entities(representations: [_Any!]!): [_Entity]!"
    end

    defmodule SDLWithoutKeyFieldsSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :test, :string
      end

      object :user do
        field :id, non_null(:id)
      end
    end

    test "does not render in sdl without @key" do
      sdl = Absinthe.Schema.to_sdl(SDLWithoutKeyFieldsSchema)
      refute sdl =~ "_entities(representations: [_Any!]!): [_Entity]!"
    end
  end
end
