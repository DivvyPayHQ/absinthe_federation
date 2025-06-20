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

        field :name, :string,
          resolve: fn
            %{upc: "789-erroneous-name"}, _, _ -> {:error, "arbitrary name error"}
            %{upc: upc}, _, _ -> {:ok, "product #{upc}"}
          end

        field :foo, non_null(:string), resolve: fn _, _, _ -> {:ok, "bar"} end

        field :_resolve_reference, :product do
          resolve(fn _, %{upc: upc} = args, _ ->
            async(fn ->
              case upc do
                "123" -> {:ok, args}
                "456" -> {:ok, args}
                "789-erroneous-name" -> {:ok, args}
                "nil" <> _ -> {:ok, nil}
                _ -> {:error, "Couldn't find product with upc #{upc}"}
              end
            end)
          end)
        end
      end

      object :user do
        extends()
        key_fields("id")

        field :id, non_null(:id), do: external()
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

    test "handles errors alongside data" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Product",
              upc: "789-erroneous-name"
            },
            {
              __typename: "Product",
              upc: "456"
            }
          ]) {
            ...on Product {
              upc
              foo
              name
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, ResolverSchema, variables: %{})

      assert %{
               data: %{
                 "_entities" => [
                   %{"foo" => "bar", "name" => nil, "upc" => "789-erroneous-name"},
                   %{"foo" => "bar", "name" => "product 456", "upc" => "456"}
                 ]
               },
               errors: [
                 %{message: "arbitrary name error", path: ["_entities", 0, "name"], locations: [%{column: 9, line: 15}]}
               ]
             } == resp
    end

    test "Handles missing data" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Product",
              upc: "nil1"
            },
            {
              __typename: "Product",
              upc: "nil22"
            }
          ]) {
            __typename
            ...on Product {
              upc
              foo
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, ResolverSchema, variables: %{})

      assert %{
               data: %{"_entities" => [nil, nil]}
             } = resp
    end

    test "Handles missing data alongside existing data" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Product",
              upc: "nil1"
            },
            {
              __typename: "Product",
              upc: "nil22"
            },
            {
              __typename: "Product",
              upc: "456"
            }
          ]) {
            __typename
            ...on Product {
              upc
              foo
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, ResolverSchema, variables: %{})

      assert %{
               data: %{"_entities" => [nil, nil, %{"__typename" => "Product", "foo" => "bar", "upc" => "456"}]}
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

  describe "resolver with batch" do
    defmodule Widget do
      defstruct [:id, :description]
    end

    defmodule Widgets do
      def batch_query_widgets(_, ids) do
        widget_data()
        |> Enum.filter(&(&1.id in ids))
        |> Map.new(&{&1.id, &1})
      end

      defp widget_data() do
        [
          %Widget{
            id: "1",
            description: "A really great widget."
          },
          %Widget{
            id: "2",
            description: "Another good, but not great widget."
          },
          %Widget{
            id: "3",
            description: "This widget should not exist. Do not query it."
          }
        ]
      end
    end

    defmodule BatchSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      import Absinthe.Resolution.Helpers, only: [batch: 3]

      query do
      end

      object :widget do
        key_fields("id")
        field :id, non_null(:id)

        field :description, :string

        field :_resolve_reference, :widget do
          resolve fn _, %{id: id}, _ ->
            batch(
              {Widgets, :batch_query_widgets},
              id,
              &{:ok, Map.get(&1, id)}
            )
          end
        end
      end
    end

    test "resolves federated entities with batch middleware" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Widget",
              id: "1"
            },
            {
              __typename: "Widget",
              id: "1"
            },
            {
              __typename: "Widget",
              id: "2"
            }
          ]) {
            ...on Widget {
              id
              description
            }
          }
        }
      """

      assert {:ok,
              %{
                data: %{
                  "_entities" => [
                    %{"id" => "1", "description" => "A really great widget."},
                    %{"id" => "1", "description" => "A really great widget."},
                    %{"id" => "2", "description" => "Another good, but not great widget."}
                  ]
                }
              }} = Absinthe.run(query, BatchSchema, variables: %{})
    end
  end

  describe "resolver with dataloader" do
    defmodule ResolveTypeSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      import Absinthe.Resolution.Helpers, only: [dataloader: 2]

      def context(ctx) do
        loader =
          Dataloader.new(get_policy: :return_nil_on_error)
          |> Dataloader.add_source(ASourceWithNonmapBatchesKey, struct(ASourceWithNonmapBatchesKey))
          |> Dataloader.add_source(ASourceWithoutBatchesKey, struct(ASourceWithoutBatchesKey))
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
          resolve dataloader(SpecItem.Loader, fn _parent, args, _res ->
                    %{batch: {{:one, SpecItem}, %{}}, item: args.item_id}
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

  describe "parent type with proper case" do
    defmodule SchemaWithLongKeyFieldName do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :test, :string
      end

      object :user do
        key_fields("global_user_id")
        extends()

        field :global_user_id, non_null(:id), do: external()

        field :verified_at, :string do
          resolve(fn %{global_user_id: global_user_id} = args, _, _ ->
            assert is_binary(global_user_id), "Expected binary global_user_id in parent: #{inspect(args)}"
            {:ok, to_string(DateTime.utc_now())}
          end)
        end
      end
    end

    test "Resolves entities properly" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "User",
              globalUserId: "123"
            },
            {
              __typename: "User",
              globalUserId: "456"
            }
          ]) {
            ...on User {
              globalUserId
              verifiedAt
            }
          }
        }
      """

      {:ok, resp} = Absinthe.run(query, SchemaWithLongKeyFieldName, variables: %{})

      assert %{
               data: %{
                 "_entities" => [
                   %{"globalUserId" => "123", "verifiedAt" => "20" <> _},
                   %{"globalUserId" => "456", "verifiedAt" => "20" <> _}
                 ]
               }
             } = resp
    end
  end

  describe "sdl" do
    defmodule SchemaWithoutExtendedTypes do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :test, :string
      end
    end

    test "omitted from the sdl if there are no extended types" do
      sdl = Absinthe.Schema.to_sdl(SchemaWithoutExtendedTypes)
      refute sdl =~ "_entities(representations: [_Any!]!): [_Entity]!"
    end

    defmodule SchemaWithExtendedTypeFromAnotherSubgraph do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :foo, :bar
      end

      object :bar do
        key_fields("id")
        extends()

        field :id, non_null(:id), do: external()
      end
    end

    test "correctly renders in the sdl if there are extended types from another subgraph" do
      sdl = Absinthe.Schema.to_sdl(SchemaWithExtendedTypeFromAnotherSubgraph)
      assert sdl =~ "_entities(representations: [_Any!]!): [_Entity]!"
    end

    defmodule SchemaWithExtendableType do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
        field :foo, :bar
      end

      object :bar do
        key_fields("id")

        field :id, :string
      end
    end

    test "correctly renders in the sdl if the schema introduces extendable types" do
      sdl = Absinthe.Schema.to_sdl(SchemaWithExtendableType)
      assert sdl =~ "_entities(representations: [_Any!]!): [_Entity]!"
    end
  end
end
