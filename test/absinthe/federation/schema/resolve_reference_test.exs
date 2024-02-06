defmodule Absinthe.Federation.Schema.ResolveReferenceTest do
  use Absinthe.Federation.Case, async: true

  defmodule HousePlant do
    defstruct [:id, :name, :water_interval]
  end

  defmodule HousePlants do
    def get_plant(id) do
      {:ok, %HousePlant{id: id, name: "Snake Plant", water_interval: 14}}
    end
  end

  defmodule TestSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
    end

    object :house_plant do
      extends()
      key_fields("id")

      field :id, :id do
        external()
      end

      field :name, :string
      field :water_interval, :integer

      field :_resolve_reference, :house_plant do
        resolve(fn _, args, _ -> HousePlants.get_plant(args.id) end)
      end
    end
  end

  describe "_resolve_reference" do
    test "resolves entity fields correctly" do
      query = """
        query GetHousePlantEntities($representations: [_Any!]!) {
          _entities(representations: $representations) {
            ... on HousePlant {
              id
              name
              waterInterval
              __typename
            }
          }
        }
      """

      id = "8b89136b-85d7-4eb4-b8a3-608a7d078c5e"

      options = [variables: %{"representations" => [%{"id" => id, "__typename" => "HousePlant"}]}]

      result = Absinthe.run(query, TestSchema, options)

      assert {:ok,
              %{
                data: %{
                  "_entities" => [
                    %{
                      "__typename" => "HousePlant",
                      "id" => ^id,
                      "name" => "Snake Plant",
                      "waterInterval" => 14
                    }
                  ]
                }
              }} = result
    end
  end
end
