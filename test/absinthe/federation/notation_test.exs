defmodule Absinthe.Federation.NotationTest do
  use Absinthe.Federation.Case, async: true

  # With Absinthe 1.7, the @link macro is not needed anymore. The way forward is to use `extend`
  # See https://github.com/DivvyPayHQ/absinthe_federation#federation-v2

  describe "macro schema" do
    defmodule MacroSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive(:link,
          url: "https://specs.apollo.dev/federation/v2.0",
          import: ["@key", "@tag"]
        )
      end

      import_sdl("scalar RandomNumber")

      query do
        field :me, :user
        field :random_number, non_null(:random_number)
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
      sdl = Absinthe.Schema.to_sdl(MacroSchema)
      assert sdl =~ "type User @extends @key(fields: \"id\")"
      assert sdl =~ "id: ID! @external"
    end

    test "can import federation 2 directives" do
      sdl = Absinthe.Schema.to_sdl(MacroSchema)
      # Absinthe import_sdl adds extra escape characters but it's compatible with the SDL syntax
      assert sdl =~ ~s(schema @link(url: "https:\\/\\/specs.apollo.dev\\/federation\\/v2.0", import: ["@key", "@tag"]\))
    end

    test "importing federation 2 directives doesn't forbid using import_sdl macro later" do
      sdl = Absinthe.Schema.to_sdl(MacroSchema)
      assert sdl =~ "scalar RandomNumber"
      assert sdl =~ "randomNumber: RandomNumber!"
    end

    test "can namespace imported directives" do
      defmodule MacroSchemaWithNamespace do
        use Absinthe.Schema
        use Absinthe.Federation.Schema

        extend schema do
          directive(:link,
            url: "https://specs.apollo.dev/federation/v2.0",
            import: ["@key", "@tag"],
            as: "federation"
          )
        end

        query do
          field :hello, :string
        end
      end

      sdl = Absinthe.Schema.to_sdl(MacroSchemaWithNamespace)

      assert sdl =~
               ~s(schema @link(url: "https:\\/\\/specs.apollo.dev\\/federation\\/v2.0", import: ["@key", "@tag"], as: "federation"\))
    end

    test "can rename imported directives" do
      defmodule MacroSchemaWithRenamedDirectives do
        use Absinthe.Schema
        use Absinthe.Federation.Schema

        extend schema do
          directive(:link,
            url: "https://specs.apollo.dev/federation/v2.0",
            import: ["@key", "@tag", %{"name" => "@override", "as" => "@replace"}],
            as: "federation")
          end

        query do
          field :hello, :string
        end
      end

      sdl = Absinthe.Schema.to_sdl(MacroSchemaWithRenamedDirectives)

      assert sdl =~
               ~s(schema @link(url: "https:\\/\\/specs.apollo.dev\\/federation\\/v2.0", import: ["@key", "@tag", {as: "@replace", name: "@override"}], as: "federation"\))
    end
  end
end
