defmodule Absinthe.Federation.NotationTest do
  use Absinthe.Federation.Case, async: true

  # With Absinthe 1.7, the @link macro is not needed anymore. The way forward is to use `extend`
  # See https://github.com/DivvyPayHQ/absinthe_federation#federation-v2

  describe "macro schema" do
    defmodule MacroSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link,
          url: "https://specs.apollo.dev/federation/v2.0",
          import: ["@key", "@tag"]
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
          directive :link,
            url: "https://specs.apollo.dev/federation/v2.0",
            import: ["@key", "@tag"],
            as: "federation"
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
          directive :link,
            url: "https://specs.apollo.dev/federation/v2.0",
            import: ["@key", "@tag", %{"name" => "@override", "as" => "@replace"}],
            as: "federation"
        end

        query do
          field :hello, :string
        end
      end

      sdl = Absinthe.Schema.to_sdl(MacroSchemaWithRenamedDirectives)

      assert sdl =~
               ~s(schema @link(url: "https:\\/\\/specs.apollo.dev\\/federation\\/v2.0", import: ["@key", "@tag", {as: "@replace", name: "@override"}], as: "federation"\))
    end

    test "schema with multiple links is valid" do
      defmodule MultipleLinkSchema do
        use Absinthe.Schema
        use Absinthe.Federation.Schema

        extend schema do
          directive :link,
            url: "https://specs.apollo.dev/federation/v2.0",
            import: ["@key", "@tag"]

          directive :link,
            url: "https://myspecs.example.org/myDirective/v1.0",
            import: ["@myDirective"]
        end

        query do
          field :hello, :string
        end
      end

      sdl = Absinthe.Schema.to_sdl(MultipleLinkSchema)

      assert sdl =~
               ~s(schema @link(url: "https:\\/\\/myspecs.example.org\\/myDirective\\/v1.0", import: ["@myDirective"]\) @link(url: "https:\\/\\/specs.apollo.dev\\/federation\\/v2.0", import: ["@key", "@tag"]\))
    end

    test "schema with multiple composeDirectives is valid" do
      defmodule ComposePrototype do
        use Absinthe.Schema.Prototype
        use Absinthe.Federation.Schema.Prototype.FederatedDirectives

        directive :custom do
          on :schema
        end

        directive :other do
          on :object
        end
      end

      defmodule MultipleComposeDirectivesSchema do
        use Absinthe.Schema
        use Absinthe.Federation.Schema, prototype_schema: ComposePrototype

        extend schema do
          directive :link, url: "https://specs.apollo.dev/federation/v2.1", import: ["@composeDirective"]
          directive :composeDirective, name: "@custom"
          directive :composeDirective, name: "@other"
        end

        query do
          field :hello, :user
        end

        object :user do
          directive :other
          field :name, :string
        end
      end

      sdl = Absinthe.Schema.to_sdl(MultipleComposeDirectivesSchema)

      assert sdl =~ ~s{schema @composeDirective(name: "@other") @composeDirective(name: "@custom")}
      assert sdl =~ ~s{directive @custom on SCHEMA}
      assert sdl =~ ~s{directive @other on OBJECT}
    end

    test "schema with an interfaceObject is valid" do
      defmodule InterfaceObjectSchema do
        use Absinthe.Schema
        use Absinthe.Federation.Schema

        extend schema do
          directive :link, url: "https://specs.apollo.dev/federation/v2.3", import: ["@interfaceObject", "@key"]
        end

        query do
          field :hello, :media
        end

        object :media do
          key_fields("id")
          interface_object()

          field :id, non_null(:id), do: external()
          field :reviews, non_null(list_of(non_null(:review)))
        end

        object :review do
          field :score, non_null(:integer)
        end
      end

      sdl = Absinthe.Schema.to_sdl(InterfaceObjectSchema)

      assert sdl =~ ~s{import: ["@interfaceObject", "@key"])}
      assert sdl =~ ~s{type Media @interfaceObject @key(fields: "id")}
    end
  end

  test "schema with authenticated directive is valid" do
    defmodule AuthenticatedSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link, url: "https://specs.apollo.dev/federation/v2.5", import: ["@authenticated"]
      end

      query do
        field :secrets, list_of(:secret)
      end

      object :secret do
        field :text, :string do
          authenticated()
        end
      end
    end

    sdl = Absinthe.Schema.to_sdl(AuthenticatedSchema)

    assert sdl =~ ~s{text: String @authenticated}
  end

  test "schema with requiresScopes directive is valid" do
    defmodule RequiresScopesSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link,
          url: "https://specs.apollo.dev/federation/v2.5",
          import: ["@requiresScopes"]
      end

      query do
        field :get_secrets, list_of(:secret) do
          requires_scopes([["read:secrets"], ["read:email"]])
        end
      end

      object :user do
        field :id, non_null(:id)
        field :username, non_null(:string)

        field :email, :string do
          requires_scopes([["read:email"]])
        end

        field :secrets, non_null(list_of(non_null(:secret)))
      end

      object :secret do
        field :author, :user
        field :text, :string
      end
    end

    sdl = Absinthe.Schema.to_sdl(RequiresScopesSchema)

    assert sdl =~ ~s{getSecrets: [Secret] @requiresScopes(scopes: [[\"read:secrets\"], [\"read:email\"]])}
    assert sdl =~ ~s{email: String @requiresScopes(scopes: [[\"read:email\"]])}
  end

  test "schema with policy directive is valid" do
    defmodule PolicySchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link,
          url: "https://specs.apollo.dev/federation/v2.6",
          import: ["@authenticated", "@policy"]
      end

      query do
        field :users, list_of(:user)
      end

      object :user do
        field :id, non_null(:id)
        field :username, non_null(:string)
        field :email, :string

        field :credit_card, :string do
          authenticated()
          policy([["read_credit_card"]])
        end
      end
    end

    sdl = Absinthe.Schema.to_sdl(PolicySchema)

    assert sdl =~ ~s{creditCard: String @authenticated @policy(policies: [["read_credit_card"]])}
  end

  test "schema with context directive is valid" do
    defmodule ContextSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link,
          url: "https://specs.apollo.dev/federation/v2.8",
          import: ["@context"]
      end

      query do
        field :users, list_of(:user)
      end

      object :user do
        context("userContext")
        field :id, non_null(:id)
        field :name, :string
      end
    end

    sdl = Absinthe.Schema.to_sdl(ContextSchema)

    assert sdl =~ ~s{type User @context(name: "userContext")}
  end

  test "schema with cost directive is valid" do
    defmodule CostSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link,
          url: "https://specs.apollo.dev/federation/v2.9",
          import: ["@cost"]
      end

      query do
        field :users, list_of(:user)
      end

      object :post do
        field :content, :string
      end

      object :user do
        field :posts, list_of(:post) do
          cost(5)
        end
      end
    end

    sdl = Absinthe.Schema.to_sdl(CostSchema)

    assert sdl =~ ~s{posts: [Post] @cost(weight: 5)}
  end

  test "schema with listSize directive is valid" do
    defmodule ListSizeSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link,
          url: "https://specs.apollo.dev/federation/v2.9",
          import: ["@listSize"]
      end

      query do
        field :users, list_of(:user)
      end

      object :post do
        field :text, :string
      end

      object :user do
        field :posts, non_null(list_of(:post)) do
          list_size(
            assumed_size: 10,
            slicing_arguments: ["first", "last"],
            sized_fields: ["postCount"],
            required_one_slicing_argument: false
          )

          arg :first, :integer
          arg :last, :integer
        end
      end
    end

    sdl = Absinthe.Schema.to_sdl(ListSizeSchema)

    assert sdl =~
             ~s{posts(first: Int, last: Int): [Post]! @listSize(assumedSize: 10, slicingArguments: ["first", "last"], sizedFields: ["postCount"], requiredOneSlicingArgument: false)}
  end

  test "schema with progressive override directive is valid" do
    defmodule ProgressiveOverrideSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link,
          url: "https://specs.apollo.dev/federation/v2.7",
          import: ["@override"]
      end

      query do
        field :bill, :bill
      end

      object :bill do
        field :id, non_null(:id)

        field :amount, :integer do
          progressive_override(from: "Payments", label: "percent(100)")
        end
      end
    end

    sdl = Absinthe.Schema.to_sdl(ProgressiveOverrideSchema)

    assert sdl =~ ~s{amount: Int @override(from: "Payments", label: "percent(100)")}
  end

  test "schema with override directive is valid" do
    defmodule OverrideSchema do
      use Absinthe.Schema
      use Absinthe.Federation.Schema

      extend schema do
        directive :link,
          url: "https://specs.apollo.dev/federation/v2.3",
          import: ["@override"]
      end

      query do
        field :bill, :bill
      end

      object :bill do
        field :id, non_null(:id)

        field :amount, :integer do
          override_from("Payments")
        end
      end
    end

    sdl = Absinthe.Schema.to_sdl(OverrideSchema)

    assert sdl =~ ~s{amount: Int @override(from: "Payments")}
  end
end
