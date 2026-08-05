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
    @query """
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

    test "resolves entity fields correctly" do
      id = "8b89136b-85d7-4eb4-b8a3-608a7d078c5e"

      options = [variables: %{"representations" => [%{"id" => id, "__typename" => "HousePlant"}]}]

      result = Absinthe.run(@query, TestSchema, options)

      assert {:ok,
              %{
                data: %{
                  "_entities" => [
                    %{
                      "__typename" => "HousePlant",
                      "id" => id,
                      "name" => "Snake Plant",
                      "waterInterval" => 14
                    }
                  ]
                }
              }} == result
    end
  end

  test "does not create new atoms for unknown representation keys" do
    id = "8b89136b-85d7-4eb4-b8a3-608a7d078c5e"

    representations = fn n ->
      for i <- 1..n do
        %{"id" => id, "__typename" => "HousePlant", "attacker_key_#{i}" => "x"}
      end
    end

    # Warm up: run once to trigger any one-time lazy module loading first
    {:ok, _warmup} = Absinthe.run(@query, TestSchema, variables: %{"representations" => representations.(1)})

    atom_count_before = :erlang.system_info(:atom_count)

    {:ok, _result} = Absinthe.run(@query, TestSchema, variables: %{"representations" => representations.(2_000)})

    atom_count_after = :erlang.system_info(:atom_count)

    # Loose assertion due to possible lazy loading while running the full test suite
    # If the code created non-existent atoms this would cause >= 2000 difference
    assert atom_count_after - atom_count_before < 99
  end

  test "unknown representation keys do not prevent resolution" do
    id = "8b89136b-85d7-4eb4-b8a3-608a7d078c5e"

    options = [
      variables: %{
        "representations" => [
          %{"id" => id, "__typename" => "HousePlant", "some_unknown_key_zzz" => "ignored"}
        ]
      }
    ]

    result = Absinthe.run(@query, TestSchema, options)

    assert {:ok,
            %{
              data: %{
                "_entities" => [
                  %{
                    "__typename" => "HousePlant",
                    "id" => id,
                    "name" => "Snake Plant",
                    "waterInterval" => 14
                  }
                ]
              }
            }} == result
  end
end
