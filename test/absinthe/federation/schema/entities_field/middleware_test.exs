defmodule Absinthe.Federation.Schema.EntitiesField.MiddlewareTest do
  use Absinthe.Federation.Case, async: true

  describe "resolve a function capture" do
    defmodule FunctionCaptureSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      query do
      end

      @impl Absinthe.Schema
      def middleware(middleware, _field, %{identifier: :item_with_module_middleware}) do
        middleware ++ [Example.Middleware]
      end

      def middleware(middleware, _field, _object) do
        middleware
      end

      object :item_with_module_middleware do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :item_with_module_middleware
      end

      object :item_with_function_middleware do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :item_with_function_middleware do
          resolve &__MODULE__.get_item/2

          middleware fn res, _ ->
            value = Map.update!(res.value, :item_id, &"FunctionMiddleware:#{&1}")
            Map.put(res, :value, value)
          end
        end
      end

      object :item_with_function_capture do
        key_fields("item_id")
        field :item_id, :string

        field :_resolve_reference, :item_with_function_capture do
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
              __typename: "ItemWithFunctionMiddleware",
              item_id: "1"
            }
          ]) {
            ...on ItemWithFunctionMiddleware {
              item_id
            }
          }
        }
      """

      assert {:ok, %{data: %{"_entities" => [%{"item_id" => "FunctionMiddleware:1"}]}}} =
               Absinthe.run(query, FunctionCaptureSchema, variables: %{})
    end

    test "handles a module-based middleware" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "ItemWithModuleMiddleware",
              item_id: "1"
            }
          ]) {
            ...on ItemWithModuleMiddleware {
              item_id
            }
          }
        }
      """

      assert {:ok, %{data: %{"_entities" => [%{"item_id" => "ModuleMiddleware:1"}]}}} =
               Absinthe.run(query, FunctionCaptureSchema, variables: %{})
    end

    test "handles a function capture" do
      query = """
        query {
          _entities(representations: [
            {
              __typename: "ItemWithFunctionCapture",
              item_id: "1"
            }
          ]) {
            ...on ItemWithFunctionCapture {
              item_id
            }
          }
        }
      """

      assert {:ok, %{data: %{"_entities" => [%{"item_id" => "1"}]}}} =
               Absinthe.run(query, FunctionCaptureSchema, variables: %{})
    end
  end
end
