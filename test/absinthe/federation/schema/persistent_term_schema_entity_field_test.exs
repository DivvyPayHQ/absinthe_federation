defmodule Absinthe.Federation.Schema.PersistentTermSchemaEntityFieldTest do
  use Absinthe.Federation.Case, async: true

  defmodule EntitySchemaWithPersistentTermProvider do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    @schema_provider Absinthe.Schema.PersistentTerm

    query do
      field :named_entity, :named_entity
    end

    interface :named_entity do
      key_fields("name")

      field :name, :string do
        resolve(fn %{name: name}, _, _ ->
          {:ok, name}
        end)
      end

      resolve_type(&resolve_type/2)

      field :_resolve_reference, :named_entity do
        resolve(fn
          _, %{name: "John"}, _ -> {:ok, %{__typename: "Person", name: "John", age: 20}}
          _, %{name: "Acme"}, _ -> {:ok, %{__typename: "Business", name: "Acme", employee_count: 10}}
        end)
      end

      defp resolve_type(%{age: _}, _), do: :person
      defp resolve_type(%{empolyee_count: _}, _), do: :business
      defp resolve_type(_, _), do: nil
    end

    object :person do
      key_fields("name")

      interface :named_entity
      import_fields(:named_entity, [:name, :_resolve_reference])
      field :age, :integer
    end

    object :business do
      key_fields("name")

      interface :named_entity
      import_fields(:named_entity, [:name, :_resolve_reference])
      field :employee_count, :integer
    end
  end

  test "Resolves entity interfaces with PersistentTerm schema provider" do
    query = """
      query {
        _entities(representations: [
          { __typename: "NamedEntity", name: "John" },
          { __typename: "NamedEntity", name: "Acme" }
        ]) {
          ...on NamedEntity {
            __typename
            name
            ... on Person {
              age
            }
            ... on Business {
              employeeCount
            }
          }
        }
      }
    """

    {:ok, resp} = Absinthe.run(query, EntitySchemaWithPersistentTermProvider, variables: %{})

    assert %{
             data: %{
               "_entities" => [
                 %{"__typename" => "Person", "name" => "John", "age" => 20},
                 %{"__typename" => "Business", "name" => "Acme", "employeeCount" => 10}
               ]
             }
           } = resp
  end
end
