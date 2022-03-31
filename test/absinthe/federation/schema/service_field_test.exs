defmodule Absinthe.Federation.Schema.ServiceFieldTest do
  use Absinthe.Federation.Case, async: true

  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.TypeReference.NonNull
  alias Absinthe.Schema
  alias Absinthe.Type.Field

  alias Absinthe.Federation.Schema.ServiceField

  describe "build" do
    test "builds field definition" do
      assert %FieldDefinition{} = ServiceField.build()
    end

    test "builds field definition with name" do
      field_definition = ServiceField.build()
      assert field_definition.name == "_service"
    end

    test "builds field definition with identifier" do
      field_definition = ServiceField.build()
      assert field_definition.identifier == :_service
    end

    test "builds field definition with type" do
      field_definition = ServiceField.build()

      assert %NonNull{
               of_type: :service
             } = field_definition.type
    end

    test "builds field definition with middleware" do
      field_definition = ServiceField.build()
      assert Enum.count(field_definition.middleware) == 1
    end
  end

  describe "resolver" do
    defmodule ResolverSchema do
      use Absinthe.Schema

      query do
        field :test, :string
      end
    end

    test "renders sdl" do
      {:ok, service} = ServiceField.resolver(%{}, %{}, %{schema: ResolverSchema})

      assert service.sdl =~ "Query"
      assert service.sdl =~ "test: String"
    end
  end

  describe "macro schema" do
    defmodule MacroSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :test, :string
      end
    end

    test "renders correctly in sdl" do
      sdl = Absinthe.Schema.to_sdl(MacroSchema)
      assert sdl =~ "_service: _Service!"
    end
  end

  describe "sdl schema" do
    defmodule SDLSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      import_sdl """
      type Query {
        currentUser: User
      }

      type User @key(fields: "id") @key(fields: "email") {
        id: ID!
        email: String!
      }
      """
    end

    test "renders multiple @key" do
      sdl = Absinthe.Schema.to_sdl(SDLSchema)
      assert sdl =~ "@key(fields: \"id\")"
      assert sdl =~ "@key(fields: \"email\")"
    end
  end

  describe "_service query field" do
    defmodule TestSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :current_user, :user
      end

      object :user do
        key_fields(["id", "email"])
        field :id, non_null(:id)
        field :email, non_null(:string)

        field :_resolve_reference, :user do
        end
      end
    end

    test "added to the schema" do
      assert %Field{name: "_service"} = Schema.lookup_type(TestSchema, :query).fields._service
    end

    test "returns sdl" do
      query = """
      {
        _service {
          sdl
        }
      }
      """

      assert %{data: %{"_service" => %{"sdl" => sdl}}} = Absinthe.run!(query, TestSchema)
      refute is_nil(sdl)
    end

    test "returns sdl with federated directives included" do
      query = """
      {
        _service {
          sdl
        }
      }
      """

      assert %{data: %{"_service" => %{"sdl" => sdl}}} = Absinthe.run!(query, TestSchema)

      assert sdl =~ "query: RootQueryType"
      assert sdl =~ "@key(fields: \"id\")"
      assert sdl =~ "@key(fields: \"email\")"
    end

    test "returns sdl with federated types/fields removed" do
      query = """
      {
        _service {
          sdl
        }
      }
      """

      assert %{data: %{"_service" => %{"sdl" => sdl}}} = Absinthe.run!(query, TestSchema)

      refute sdl =~ "_service: _Service!"
      refute sdl =~ "_resolveReference"
    end
  end
end
