defmodule Absinthe.Federation.Schema.EntitiesField.DataloaderTest do
  use Absinthe.Federation.Case, async: true

  setup do
    {:ok, source} = start_supervised(Example.Source)
    Example.Source.put(%{"1" => %Example.Item{item_id: "1"}, "3" => %Example.Item{item_id: "3"}})

    %{source: source}
  end

  describe "resolver with dataloader" do
    defmodule ExampleDataloaderSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      import Absinthe.Resolution.Helpers, only: [on_load: 2, dataloader: 3]

      def context(ctx) do
        loader =
          Dataloader.new()
          |> Dataloader.add_source(Example.Source, Dataloader.KV.new(&Example.Source.run_batch/2))

        Map.put(ctx, :loader, loader)
      end

      def plugins do
        [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
      end

      query do
      end

      object :normal_item do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :normal_item do
          resolve fn %{item_id: id, __typename: typename}, _res ->
            {:ok, %{item_id: id, __typename: typename}}
          end
        end
      end

      object :dataloaded_item do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :dataloaded_item do
          resolve dataloader(
                    Example.Source,
                    fn _parent, args, _res -> %{batch: {:one, Example.Item, %{}}, item: args.item_id} end,
                    callback: fn item, _parent, _args ->
                      if item do
                        item = Map.drop(item, [:__struct__])
                        item = Map.put(item, :__typename, "DataloadedItem")
                        {:ok, item}
                      else
                        {:ok, item}
                      end
                    end
                  )
        end
      end

      object :on_load_item do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :on_load_item do
          resolve fn %{item_id: id}, %{context: %{loader: loader}} ->
            batch_key = {:one, Example.Item, %{}}
            item_key = id

            loader
            |> Dataloader.load(Example.Source, batch_key, item_key)
            |> on_load(fn loader ->
              result = Dataloader.get(loader, Example.Source, batch_key, item_key)

              if result do
                result = Map.drop(result, [:__struct__])
                {:ok, Map.put(result, :__typename, "DataloadedItem")}
              else
                {:ok, nil}
              end
            end)
          end
        end
      end
    end

    test "handles dataloader resolvers" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "DataloadedItem",
              item_id: "1"
            },
            {
              __typename: "NormalItem",
              item_id: "1"
            },
            {
              __typename: "OnLoadItem",
              item_id: "1"
            },
            {
              __typename: "OnLoadItem",
              item_id: "2"
            }
          ]) {
            ...on DataloadedItem {
              item_id
            }
            ...on NormalItem {
              item_id
            }
            ...on OnLoadItem {
              item_id
            }
          }
        }
      """

      assert {:ok, %{data: %{"_entities" => [%{"item_id" => "1"}, %{"item_id" => "1"}, %{"item_id" => "1"}, nil]}}} =
               Absinthe.run(query, ExampleDataloaderSchema, variables: %{})
    end
  end
end
