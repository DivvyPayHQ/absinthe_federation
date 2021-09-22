defmodule Absinthe.Federation.Schema.EntityUnionTest do
  use Absinthe.Federation.Case, async: true

  describe "entity macro" do
    defmodule UserEntity do
      defstruct [:id]
    end

    defmodule EntitySchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      entity do
        types [:user]
        resolve_type fn %UserEntity{}, _ -> :user end
      end

      query do
        field :me, :user
      end

      object :user do
        key_fields("id")
        field :id, non_null(:id)

        field :_resolve_reference, :user do
          resolve(fn _, %{id: id}, _ -> {:ok, %UserEntity{id: id}} end)
        end
      end
    end

    test "works" do
      query = """
        {
          _entities(representations: [{__typename: "User", id: "123"}]) {
            ...on User {
              id
            }
          }
        }
      """

      assert %{data: %{"_entities" => [%{"id" => "123"}]}} = Absinthe.run!(query, EntitySchema)
    end
  end
end
