defmodule Absinthe.Federation.NotationTest do
  use Absinthe.Federation.Case, async: true

  defmodule FederatedMacroSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      field :me, :user
    end

    object :user do
      key_fields("id")
      extends()

      field :id, non_null(:id) do
        external()
      end
    end
  end

  test "can use federation macros" do
    sdl = Absinthe.Schema.to_sdl(FederatedMacroSchema)
    assert sdl =~ "type User @extends @key(fields: \"id\")"
    assert sdl =~ "id: ID! @external"
  end

  defmodule AbsintheMacroSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      field :me, :user
    end

    object :user do
      directive :key, fields: "id"
      directive :extends

      field :id, non_null(:id) do
        directive :external
      end

      field :name, :string, directives: [:provides]
    end
  end

  test "can use absinthe directive macros" do
    sdl = Absinthe.Schema.to_sdl(AbsintheMacroSchema)
    assert sdl =~ "type User @extends @key(fields: \"id\")"
    assert sdl =~ "id: ID! @external"
    assert sdl =~ "name: String @provides"
  end
end
