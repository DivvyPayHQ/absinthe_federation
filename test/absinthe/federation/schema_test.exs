defmodule Absinthe.Federation.SchemaTest do
  use Absinthe.Federation.Case, async: true

  defmodule TestSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()

      # absinthe requires query to contain at least 1 root query field
      field :foo, :boolean
    end

    object :user do
      extends()
      key_fields("id")

      field :id, non_null(:id) do
        external()
      end

      field :profile, non_null(:user_profile)

      field :extended_field, :boolean, resolve: fn _, _ -> {:ok, true} end

      field :_resolve_reference, :user
    end

    object :user_profile do
      field :avatar_url, :string
    end
  end

  describe "to_federated_sdl/1" do
    test "renders extended types with no root field entry in the schema" do
      sdl = Absinthe.Federation.to_federated_sdl(TestSchema)

      assert sdl =~ "type User @extends @key(fields: \"id\") {"
    end

    test "renders types that depend on extended types" do
      sdl = Absinthe.Federation.to_federated_sdl(TestSchema)

      assert sdl =~ "type UserProfile {"
    end

    test "does not render _resolve_reference fields" do
      sdl = Absinthe.Federation.to_federated_sdl(TestSchema)

      refute sdl =~ "_resolveReference"
    end

    # TODO: Due to an issue found with rendering the SDL we had to revert this functionality
    # https://github.com/DivvyPayHQ/absinthe_federation/issues/28
    @tag :skip
    test "does not render root federated fields" do
      sdl = Absinthe.Federation.to_federated_sdl(TestSchema)

      refute sdl =~ "_service: _Service!"
      refute sdl =~ "_entities(representations: [_Any!]!): [_Entity]!"
    end
  end
end
