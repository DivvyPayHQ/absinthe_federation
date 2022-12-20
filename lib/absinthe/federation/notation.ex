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
  The `@link` directive links definitions from an external specification to this schema.
  Every Federation 2 subgraph uses the `@link` directive to import the other federation-specific directives.

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
