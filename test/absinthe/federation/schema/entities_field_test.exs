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
        field :foo, non_null(:string), resolve: fn _, _, _ -> {:ok, "bar"} end

        field :_resolve_reference, :product do
          resolve(fn _, %{upc: upc} = args, _ ->
            async(fn _ ->
              case upc do
                "123" -> {:ok, args}
                "456" -> {:ok, args}
                _ -> {:error, "Couldn't find product with upc #{upc}"}
              end
            end)
          end)
        end
      end

      object :user do
        extends()
        key_fields("id")

        field :id, non_null(:id)
        field :foo, non_null(:string), resolve: fn _, _, _ -> {:ok, "bar"} end
      end
    end

    test "resolves all types fulfilling the _Entity type" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Product",
              upc: "123"
            },
            {
              __typename: "Product",
              upc: "456"
            }
          ]) {
            ...on Product {
              upc
              foo
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, ResolverSchema, variables: %{})

      assert %{data: %{"_entities" => [%{"upc" => "123", "foo" => "bar"}, %{"foo" => "bar", "upc" => "456"}]}} = resp
    end

    test "handles errors" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Product",
              upc: "1"
            },
            {
              __typename: "Product",
              upc: "2"
            }
          ]) {
            ...on Product {
              upc
              foo
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, ResolverSchema, variables: %{})

      assert %{
               data: nil,
               errors: [
                 %{
                   locations: [%{column: 5, line: 2}],
                   message: "Couldn't find product with upc 1",
                   path: ["_entities"]
                 },
                 %{
                   locations: [%{column: 5, line: 2}],
                   message: "Couldn't find product with upc 2",
                   path: ["_entities"]
                 }
               ]
             } = resp
    end

    test "falls back to default _resolve_reference implementation" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "User",
              id: "123"
            },
            {
              __typename: "User",
              id: "456"
            }
          ]) {
            ...on User {
              id
              foo
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, ResolverSchema, variables: %{})

      assert %{data: %{"_entities" => [%{"id" => "123", "foo" => "bar"}, %{"foo" => "bar", "id" => "456"}]}} = resp
    end
  end

  describe "resolver with dataloader" do
    defmodule ResolveTypeSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      import Absinthe.Resolution.Helpers, only: [dataloader: 1]

      def context(ctx) do
        loader =
          Dataloader.new(get_policy: :return_nil_on_error)
          |> Dataloader.add_source(
            SpecItem.Loader,
            SpecItem.Loader.data()
          )

        Map.put(ctx, :loader, loader)
      end

      def plugins do
        [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
      end

      query do
      end

      object :spec_item do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :spec_item do
          resolve(fn _root, %{item_id: id} = args, info ->
            dataloader(SpecItem.Loader).(id, args, info)
          end)
        end
      end
    end

    test "handles dataloader resolvers" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "SpecItem",
              item_id: "1"
            },
            {
              __typename: "SpecItem",
              item_id: "2"
            }
          ]) {
            ...on SpecItem {
              item_id
            }
          }
        }
      """

      assert {:ok, %{data: %{"_entities" => [%{"item_id" => "1"}, %{"item_id" => "2"}]}}} =
               Absinthe.run(query, ResolveTypeSchema, variables: %{})
    end

    test "handles dataloader errors" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "SpecItem",
              item_id: "1"
            },
            {
              __typename: "SpecItem",
              item_id: "3"
            }
          ]) {
            ...on SpecItem {
              item_id
            }
          }
        }
      """

      assert {:ok, %{data: %{"_entities" => [%{"item_id" => "1"}, nil]}}} =
               Absinthe.run(query, ResolveTypeSchema, variables: %{})
    end
  end

  describe "resolver with nested fields" do
    defmodule NestedResolverSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      @products [
        %{upc: "123", sku: "federation", variation: %{id: "fed"}, __typename: "Product"},
        %{upc: "456", sku: "federation", variation: %{id: "abs"}, __typename: "Product"}
      ]

      query do
        field :test, :string
      end

      object :product_variation do
        field :id, non_null(:id)
      end

      object :product do
        key_fields(["upc", "sku variation { id }"])
        field :upc, non_null(:string)
        field :sku, non_null(:string)
        field :variation, non_null(:product_variation)

        field :_resolve_reference, :product do
          resolve(fn
            _, %{upc: upc}, _ ->
              {:ok, @products |> Enum.find(&(&1.upc == upc))}

            _, %{sku: sku, variation: %{id: variation_id}}, _ ->
              {:ok, @products |> Enum.find(&(&1.variation.id == variation_id && &1.sku == sku))}
          end)
        end
      end
    end

    test "resolves all types by single key" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Product",
              upc: "123"
            }
          ]) {
            ...on Product {
              upc
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, NestedResolverSchema, variables: %{})

      assert resp == %{data: %{"_entities" => [%{"upc" => "123"}]}}
    end

    test "resolves all types by nested keys" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Product",
              sku: "federation",
              variation: {id: "abs"}
            }
          ]) {
            ...on Product {
              upc
              sku
              variation {
                id
              }
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, NestedResolverSchema, variables: %{})

      assert resp == %{
               data: %{"_entities" => [%{"upc" => "456", "sku" => "federation", "variation" => %{"id" => "abs"}}]}
             }
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
