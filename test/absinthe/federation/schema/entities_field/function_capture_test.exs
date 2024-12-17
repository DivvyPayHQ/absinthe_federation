defmodule Absinthe.Federation.Schema.EntitiesField.FunctionCaptureTest do
  use Absinthe.Federation.Case, async: true

  describe "resolve a function capture" do
    defmodule EctoDataloaderSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
      end

      object :item_with_middleware do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :item do
          resolve &__MODULE__.get_item/2
          middleware fn res, _ ->
            value = Map.update!(res.value, :item_id, & "#{&1}#{&1}")
            Map.put(res, :value, value)
          end
        end
      end

      object :item do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :item do
          resolve &__MODULE__.get_item/2
        end
      end

      def get_item(args, _res) do
        {:ok, args}
      end
    end

    test "handles a post-resolution middleware" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "ItemWithMiddleware",
              item_id: "1"
            }
          ]) {
            ...on ItemWithMiddleware {
              item_id
            }
          }
        }
      """

      assert {:ok, %{data: %{"_entities" => [%{"item_id" => "11"}]}}} =
               Absinthe.run(query, EctoDataloaderSchema, variables: %{})
    end

    test "handles a function capture" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "Item",
              item_id: "1"
            }
          ]) {
            ...on Item {
              item_id
            }
          }
        }
      """

      assert {:ok, %{data: %{"_entities" => [%{"item_id" => "1"}]}}} =
               Absinthe.run(query, EctoDataloaderSchema, variables: %{})
    end
  end
end
