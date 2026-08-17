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

  test "does not create an atom for an unknown representation key" do
    id = "8b89136b-85d7-4eb4-b8a3-608a7d078c5e"
    unknown_key = "arbitrary_key_#{System.unique_integer([:positive])}"

    options = [
      variables: %{"representations" => [%{"id" => id, "__typename" => "HousePlant", unknown_key => "x"}]}
    ]

    {:ok, _result} = Absinthe.run(@query, TestSchema, options)

    assert_raise ArgumentError, ~r/not an already existing atom/, fn -> String.to_existing_atom(unknown_key) end
  end

  test "_resolve_reference is hidden from introspection" do
    query = """
      {
        __type(name: "HousePlant") {
          fields {
            name
          }
        }
      }
    """

    assert {:ok, %{data: %{"__type" => %{"fields" => fields}}}} = Absinthe.run(query, TestSchema)

    refute Enum.any?(fields, &(&1["name"] == "_resolveReference"))
    assert Enum.map(fields, & &1["name"]) |> Enum.sort() == ["id", "name", "waterInterval"]
  end

  test "_resolve_reference cannot be queried directly" do
    query = "{ __resolve_reference { id } }"

    assert {:ok, %{errors: [%{message: message}]}} = Absinthe.run(query, TestSchema)
    assert message =~ "Cannot query field"
  end

  test "_resolve_reference is still removed from the federated SDL" do
    sdl = Absinthe.Federation.Schema.to_federated_sdl(TestSchema)

    refute sdl =~ "resolveReference"
    refute sdl =~ "resolve_reference"
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
