defmodule Absinthe.Federation.Notation do
  @moduledoc """
  Module that includes macros for annotating a schema with federation directives.

  ## Example

      defmodule MyApp.MySchema.Types do
        use Absinthe.Schema.Notation
      + use Absinthe.Federation.Notation

      end
  """

  defmacro __using__(_opts) do
    notations()
  end

  @spec notations() :: Macro.t()
  defp notations() do
    quote do
      import Absinthe.Federation.Notation, only: :macros
    end
  end

  @doc """
  Adds a `@key` directive to the type which indicates a combination of fields
  that can be used to uniquely identify and fetch an object or interface.
  This allows the type to be extended by other services.
  A string rather than atom is used here to support composite keys e.g. `id organization { id }`

  ## Example

      object :user do
        key_fields("id")
        field :id, non_null(:id)
      end


  ## SDL Output

      type User @key(fields: "id") {
        id: ID!
      }
  """
  defmacro key_fields(fields) when is_binary(fields) or is_list(fields) do
    quote do
      meta :key_fields, unquote(fields)
    end
  end

  @doc """
  Adds the `@external` directive to the field which marks a field as owned by another service.
  This allows service A to use fields from service B while also knowing at runtime the types of that field.

  ## Example

      object :user do
        extends()
        key_fields("email")
        field :email, :string do
          external()
        end
        field :reviews, list_of(:review)
      end


  ## SDL Output

      # extended from the Users service
      type User @key(fields: "email") @extends {
        email: String @external
        reviews: [Review]
      }

  This type extension in the Reviews service extends the User type from the Users service.
  It extends it for the purpose of adding a new field called reviews, which returns a list of `Review`s.
  """
  defmacro external() do
    quote do
      meta :external, true
    end
  end

  @doc """
  Adds the `@requires` directive which is used to annotate the required input fieldset from a base type for a resolver.
  It is used to develop a query plan where the required fields may not be needed by the client,
  but the service may need additional information from other services.

  ## Example

      object :user do
        extends()
        key_fields("id")
        field :id, non_null(:id) do
          external()
        end
        field :email, :string do
          external()
        end
        field :reviews, list_of(:review) do
          requires_fields("email")
        end
      end


  ## SDL Output

      # extended from the Users service
      type User @key(fields: "id") @extends {
        id: ID! @external
        email: String @external
        reviews: [Review] @requires(fields: "email")
      }

  In this case, the Reviews service adds new capabilities to the `User` type by providing
  a list of `reviews` related to a `User`. In order to fetch these `reviews`, the Reviews service needs
  to know the `email` of the `User` from the Users service in order to look up the `reviews`.
  This means the `reviews` field / resolver requires the `email` field from the base `User` type.
  """
  defmacro requires_fields(fields) when is_binary(fields) do
    quote do
      meta :requires_fields, unquote(fields)
    end
  end

  @doc """
  Adds the `@provides` directive which is used to annotate the expected returned fieldset
  from a field on a base type that is guaranteed to be selectable by the gateway.

  ## Example

      object :review do
        key_fields("id")
        field :id, non_null(:id)
        field :product, :product do
          provides_fields("name")
        end
      end

      object :product do
        extends()
        key_fields("upc")
        field :upc, :string do
          external()
        end
        field :name, :string do
          external()
        end
      end

  ## SDL Output

      type Review @key(fields: "id") {
        product: Product @provides(fields: "name")
      }

      type Product @key(fields: "upc") @extends {
        upc: String @external
        name: String @external
      }

  When fetching `Review.product` from the Reviews service,
  it is possible to request the `name` with the expectation that the Reviews service
  can provide it when going from review to product. `Product.name` is an external field
  on an external type which is why the local type extension of `Product` and annotation of `name` is required.
  """
  defmacro provides_fields(fields) when is_binary(fields) do
    quote do
      meta :provides_fields, unquote(fields)
    end
  end

  @doc """
  Adds the `@extends` directive to the type to indicate that the type as owned by another service.

  ## Example

      object :user do
        extends()
        key_fields("id")
        field :id, non_null(:id)
      end


  ## SDL Output

      type User @key(fields: "id") @extends {
        id: ID!
      }
  """
  defmacro extends() do
    quote do
      meta :extends, true
    end
  end

  @doc """
  Adds the `@shareable` directive to the type to indicate that a field can be resolved by multiple subgraphs.

  ## Example

      object :user do
        key_fields("id")
        shareable()
        field :id, non_null(:id)
      end


  ## SDL Output

      type User @key(fields: "id") @shareable {
        id: ID!
      }
  """
  defmacro shareable() do
    quote do
      meta :shareable, true
    end
  end

  @doc """
  Adds The @override directive is used to indicate that the current subgraph is
  taking responsibility for resolving the marked field away from the
  subgraph specified in the from argument.

  ## Example

      object :user do
        key_fields("id")
        field :id, non_null(:id)

        field :name, :string do
          override_from("SubgraphA")
        end
      end


  ## SDL Output

      type User @key(fields: "id") {
        id: ID!
        name: String @override(from: "SubgraphA")
      }
  """
  defmacro override_from(subgraph) when is_binary(subgraph) do
    quote do
      meta :override_from, unquote(subgraph)
    end
  end

  @doc """
  The progressive `@override` feature enables the gradual, progressive deployment of a subgraph with an @override field.

  ## Example

      object :user do
        key_fields("id")
        field :id, non_null(:id)

        field :name, :string do
          progressive_override(from: "SubgraphA", label: "percent(20)")
        end
      end


  ## SDL Output

      type User @key(fields: "id") {
        id: ID!
        name: String @override(from: "SubgraphA", label: "percent(20)")
      }
  """
  defmacro progressive_override(args) when is_list(args) do
    quote do
      meta :progressive_override, unquote(args)
    end
  end

  @doc """
  The `@inaccessible` directive indicates that a field or type should be omitted from the gateway's API schema,
  even if it's also defined in other subgraphs.

  ## Example

      object :user do
        key_fields("id")
        field :id, non_null(:id)

        field :name, :string do
          inaccessible()
        end
      end


  ## SDL Output

      type User @key(fields: "id") {
        id: ID!
        name: String @inaccessible
      }
  """
  defmacro inaccessible() do
    quote do
      meta :inaccessible, true
    end
  end

  @doc """
  Adds the `@interfaceObject` directive to the field which indicates that the
  object definition serves as an abstraction of another subgraph's entity
  interface. This abstraction enables a subgraph to automatically contribute
  fields to all entities that implement a particular entity interface.

  During composition, the fields of every `@interfaceObject` are added both to
  their corresponding interface definition and to all entity types that
  implement that interface.

  More information can be found on:
  https://www.apollographql.com/docs/federation/federated-types/interfaces

  ## Example

      object :media do
        key_fields("id")
        interface_object()

        field :id, non_null(:id), do: external()
        field :reviews, non_null(list_of(non_null(:review)))
      end

      object :review do
        field :score, non_null(:integer)
      end


  ## SDL Output

      type Media @interfaceObject @key(fields: "id") {
        id: ID! @external
        reviews: [Review!]!
      }

      type Review {
        score: Int!
      }

  """
  defmacro interface_object() do
    quote do
      meta :interface_object, true
    end
  end

  @doc """
  The `@tag` directive indicates whether to include or exclude the field/type from your contract schema.

  ## Example

      object :user do
        key_fields("id")
        field :id, non_null(:id)

        field :ssn, :string do
          tag("internal")
        end
      end


  ## SDL Output

      type User @key(fields: "id") {
        id: ID!
        name: String @tag(name: "internal")
      }
  """
  defmacro tag(name) when is_binary(name) do
    quote do
      meta :tag, unquote(name)
    end
  end

  @doc """
  The `@authenticated` directive marks specific fields and types as requiring authentication.

  ## Example

      object :secret do
        field :text, :string do
          authenticated()
        end
      end


  ## SDL Output

      type Secret {
        text: String @authenticated
      }
  """
  defmacro authenticated() do
    quote do
      meta :authenticated, true
    end
  end

  @doc """
  The `@requiresScopes` directive marks fields and types as restricted based on required scopes.

  ## Example

      object :user do
        field :id, non_null(:id)
        field :username, :string
        field :email, :string do
          requires_scopes([["read:email"]])
        end
        field :profile_image, :string
      end


  ## SDL Output

     type User {
       id: ID!
       username: String
       email: String @requiresScopes(scopes: [["read:email"]])
       profileImage: String
     }
  """
  defmacro requires_scopes(scopes) when is_list(scopes) do
    quote do
      meta :requires_scopes, unquote(scopes)
    end
  end

  @doc """
  The `@policy` directive marks fields and types as restricted based on authorization policies evaluated in a Rhai script or coprocessor.
  This enables custom authorization validation beyond authentication and scopes.

  ## Example

      object :user do
        field :id, non_null(:id)
        field :username, :string
        field :email, :string 
        field :profile_image, :string
        field :credit_card, :string do
         policy([["read_credit_card"]])
        end
      end


  ## SDL Output

    type User {
      id: ID!
      username: String
      email: String
      profileImage: String
      credit_card: String @policy(policies: [["read_credit_card"]])
    }
  """
  defmacro policy(policies) when is_list(policies) do
    quote do
      meta :policies, unquote(policies)
    end
  end

  @doc """
  The `@listSize` directive is used to customize the cost calculation of the demand control feature of GraphOS Router.

  ## Example

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


  ## SDL Output

    type User {
      posts(first: Int, last: Int): [Post]! @listSize(assumedSize: 10, slicingArguments: ["first", "last"], sizedFields: ["postCount"], requiredOneSlicingArgument: false)
    }
  """
  defmacro list_size(opts) when is_list(opts) do
    quote do
      meta :list_size, unquote(opts)
    end
  end

  @doc """
  The `@cost` directive defines a custom weight for a schema location. For GraphOS Router, it customizes the operation cost calculation of the demand control feature.

  ## Example

      object :user do
        field :posts, list_of(:post) do
          cost(5)
          resolve &PostResolvers.list_for_user/3
        end
      end

  ## SDL Output

      type User {
        posts: [Post] @cost(weight: 5)
      }
  """
  defmacro cost(weight) when is_integer(weight) do
    quote do
      meta :cost, unquote(weight)
    end
  end

  @doc """
  The `@context` directive defines a named context from which a field of the annotated type can be passed to a receiver of the context.
  The receiver must be a field annotated with the `@fromContext` directive.

  ## Example

      object :user do
        context("userContext")
        field :id, non_null(:id)
        field :name, :string
      end

  ## SDL Output

      type User @context(name: "userContext") {
        id: ID!
        name: String
      }
  """
  defmacro context(name) when is_binary(name) do
    quote do
      meta :context, unquote(name)
    end
  end

  @doc """
  The `@link` directive links definitions from an external specification to this schema.
  Every Federation 2 subgraph uses the `@link` directive to import the other federation-specific directives.

  **NOTE:** If you're using Absinthe v1.7.1 or later, instead of using this macro, it's preferred to use the
  `extend schema` method you can find in the [README](README.md#federation-v2).

  ## Example

      link(url: "https://specs.apollo.dev/federation/v2.0", import: ["@key", "@tag", "@shareable"])

      query do
        field :me, :user
      end

      object :user do
        key_fields("id")
        shareable()
        field :id, non_null(:id)

        field :ssn, :string do
          tag("internal")
        end
      end

  ## SDL Output
      schema @link(url: \"url: https:\\/\\/specs.apollo.dev\\/federation\\/v2.0\", import: ["@key", "@tag", "@shareable"])

      type User @key(fields: "id") @shareable {
        id: ID!
        name: String @tag(name: "internal")
      }
  """
  defmacro link(opts) when is_list(opts) do
    quote do
      opts = unquote(opts)
      query_type = Keyword.get(opts, :query_type_name, "RootQueryType")
      mutation_type = Keyword.get(opts, :mutation_type_name, "RootMutationType")
      url_arg = opts |> Keyword.fetch!(:url) |> (&~s(url: \"#{&1}\")).()

      import_arg =
        opts
        |> Keyword.fetch!(:import)
        |> Enum.map(fn
          arg when is_binary(arg) -> ~s("#{arg}")
          %{name: name, as: renamed_as} -> ~s({ name: "#{name}", as: "#{renamed_as}" })
        end)
        |> (&", import: [#{&1}]").()

      namespace_arg =
        case Keyword.get(opts, :as) do
          namespace when is_nil(namespace) -> ""
          namespace when is_binary(namespace) -> ~s(, as: "#{namespace}")
        end

      args = "#{url_arg}#{import_arg}#{namespace_arg}"

      import_sdl """
        schema @link(#{args}) {
          query: #{query_type}
          mutation: #{mutation_type}
        }
      """
    end
  end
end
