defmodule ProductsWeb.Schema do
  defmodule Product do
    defstruct [:id, :sku, :package, :variation]
  end

  defmodule DeprecatedProduct do
    defstruct [:sku, :package, :reason]

    defimpl Absinthe.Federation.Schema.EntityUnion.Resolver do
      def resolve_type(_, _), do: :deprecated_product
    end
  end

  defmodule ProductResearch do
    defstruct [:study, :outcome]

    defimpl Absinthe.Federation.Schema.EntityUnion.Resolver do
      def resolve_type(_, _), do: :product_research
    end
  end

  defmodule User do
    defstruct [:email, :name, :total_products_created, :years_of_employment]
  end

  defmodule Prototype do
    use Absinthe.Schema.Prototype
    use Absinthe.Federation.Schema.Prototype.FederatedDirectives

    directive :custom do
      on :object
    end
  end

  use Absinthe.Schema
  use Absinthe.Federation.Schema, prototype_schema: Prototype

  extend schema do
    directive :composeDirective, name: "@custom"
    directive :link, url: "https://divvypay.com/test/v2.4", import: ["@custom"]

    directive :link,
      url: "https://specs.apollo.dev/federation/v2.1",
      import: [
        "@extends",
        "@external",
        "@inaccessible",
        "@key",
        "@override",
        "@provides",
        "@requires",
        "@shareable",
        "@tag",
        "@composeDirective"
      ]
  end

  @desc """
  type Product @key(fields: "id") @key(fields: "sku package") @key(fields: "sku variation { id }") {
    id: ID!
    sku: String
    package: String
    variation: ProductVariation
    dimensions: ProductDimension
    createdBy: User @provides(fields: "totalProductsCreated")
    notes: String @tag(name: "internal")
    research: [ProductResearch!]!
  }
  """
  object :product do
    key_fields(["id", "sku package", "sku variation { id }"])
    directive :custom

    field :id, non_null(:id)
    field :sku, :string
    field :package, :string
    field :variation, :product_variation

    field :dimensions, :product_dimension do
      resolve(&resolve_product_dimensions/3)
    end

    field :created_by, :user do
      provides_fields("totalProductsCreated")
      resolve(&resolve_product_created_by/3)
    end

    field :notes, :string do
      tag("internal")
    end

    field :research, non_null(list_of(non_null(:product_research))) do
      resolve(&resolve_product_research/3)
    end

    field :_resolve_reference, :product do
      resolve(&resolve_product_reference/2)
    end
  end

  @desc """
  type DeprecatedProduct @key(fields: "sku package") {
    sku: String!
    package: String!
    reason: String
    createdBy: User
  }
  """
  object :deprecated_product do
    key_fields("sku package")
    field :sku, non_null(:string)
    field :package, non_null(:string)
    field :reason, :string

    field :created_by, :user do
      resolve(&resolve_deprecated_product_created_by/3)
    end

    field :_resolve_reference, :deprecated_product do
      resolve(&resolve_deprecated_product_reference/2)
    end
  end

  @desc """
  type ProductVariation {
    id: ID!
  }
  """
  object :product_variation do
    field :id, non_null(:id)
  end

  @desc """
  type ProductResearch @key(fields: "study { caseNumber }") {
    study: CaseStudy!
    outcome: String
  }
  """
  object :product_research do
    key_fields("study { case_number }")
    field :study, non_null(:case_study)
    field :outcome, :string

    field :_resolve_reference, :product_research do
      resolve(fn representation, _ctx ->
        {:ok,
         Enum.find(product_research(), fn p ->
           representation.study.case_number === p.study.case_number
         end)}
      end)
    end
  end

  @desc """
  type CaseStudy {
    caseNumber: ID!
    description: String
  }
  """
  object :case_study do
    field :case_number, non_null(:id)
    field :description, :string
  end

  @desc """
  type ProductDimension @shareable {
    size: String
    weight: Float
    unit: String @inaccessible
  }
  """
  object :product_dimension do
    shareable()
    field :size, :string
    field :weight, :float

    field :unit, :string do
      inaccessible()
    end
  end

  @desc """
  extend type Query {
    product(id: ID!): Product
    deprecatedProduct(sku: String!, package: String!): DeprecatedProduct @deprecated(reason: "Use product query instead")
  }
  """
  query name: "Query" do
    extends()

    field :product, :product do
      arg :id, non_null(:id)
      resolve(&resolve_product/3)
    end

    field :deprecated_product, :deprecated_product do
      deprecate "Use product query instead"
      arg :sku, non_null(:string)
      arg :package, non_null(:string)
      resolve(&resolve_deprecated_product/2)
    end
  end

  @desc """
  extend type User @key(fields: "email") {
    averageProductsCreatedPerYear: Int @requires(fields: "totalProductsCreated yearsOfEmployment")
    email: ID! @external
    name: String @shareable @override(from: "users")
    totalProductsCreated: Int @external
    yearsOfEmployment: Int! @external
  }
  """
  object :user do
    extends()
    key_fields("email")

    field :average_products_created_per_year, :integer do
      requires_fields("totalProductsCreated yearsOfEmployment")

      resolve(fn
        %{
          email: "support@apollographql.com",
          total_products_created: total_products_created,
          years_of_employment: years_of_employment
        },
        _args,
        _ctx ->
          # Had to truncate this decimal value since the schema says its an Int and
          # absinthe doesn't allow you to encode a decimal as an integer
          {:ok, trunc(total_products_created / years_of_employment)}

        _user, _args, _ctx ->
          {:error, "user.email was not 'support@apollographql.com'"}
      end)
    end

    field :email, non_null(:id) do
      external()
    end

    field :name, :string do
      shareable()
      override_from("users")
    end

    field :total_products_created, :integer do
      external()
    end

    field :years_of_employment, non_null(:integer) do
      external()
    end

    field :_resolve_reference, :user do
      resolve(&resolve_user_reference/2)
    end
  end

  defp resolve_product(_parent, %{id: id}, _ctx) do
    {:ok, Enum.find(products(), &(&1.id == id))}
  end

  defp resolve_product_created_by(_product, _, _ctx) do
    {:ok, List.first(users())}
  end

  defp resolve_product_research(%{id: "apollo-federation"}, _, _ctx) do
    {:ok, [Enum.at(product_research(), 0)]}
  end

  defp resolve_product_research(%{id: "apollo-studio"}, _, _ctx) do
    {:ok, [Enum.at(product_research(), 1)]}
  end

  defp resolve_product_research(_args, _, _ctx) do
    {:ok, []}
  end

  defp resolve_product_dimensions(_product, _, _ctx) do
    {:ok, %{size: "small", weight: 1, unit: "kg"}}
  end

  defp resolve_product_reference(%{id: id}, _ctx) do
    {:ok, Enum.find(products(), &(&1.id == id))}
  end

  defp resolve_product_reference(%{sku: sku, package: package}, _ctx) do
    {:ok, Enum.find(products(), &(&1.sku == sku and &1.package == package))}
  end

  defp resolve_product_reference(%{sku: sku, variation: %{id: variation_id}}, _ctx) do
    {:ok, Enum.find(products(), &(&1.sku == sku and &1.variation.id == variation_id))}
  end

  defp resolve_user_reference(%{email: email} = representation, _ctx) do
    case Enum.find(users(), &(&1.email == email)) do
      %User{} = user ->
        {:ok,
         %{
           user
           | total_products_created: representation[:total_products_created],
             years_of_employment: representation[:years_of_employment]
         }}

      nil ->
        {:ok, nil}
    end
  end

  defp resolve_deprecated_product_reference(
         %{sku: "apollo-federation-v1", package: "@apollo/federation-v1"},
         _ctx
       ) do
    {:ok,
     %DeprecatedProduct{
       sku: "apollo-federation-v1",
       package: "@apollo/federation-v1",
       reason: "Migrate to Federation V2"
     }}
  end

  defp resolve_deprecated_product_reference(_args, _ctx) do
    {:ok, nil}
  end

  defp resolve_deprecated_product(
         %{sku: "apollo-federation-v1", package: "@apollo/federation-v1"},
         _ctx
       ) do
    {:ok,
     %DeprecatedProduct{
       sku: "apollo-federation-v1",
       package: "@apollo/federation-v1",
       reason: "Migrate to Federation V2"
     }}
  end

  defp resolve_deprecated_product(_args, _ctx) do
    {:ok, nil}
  end

  defp resolve_deprecated_product_created_by(_deprecated_product, _args, _ctx) do
    {:ok, List.first(users())}
  end

  defp products(),
    do: [
      %Product{
        id: "apollo-federation",
        sku: "federation",
        package: "@apollo/federation",
        variation: %{
          id: "OSS"
        }
      },
      %Product{
        id: "apollo-studio",
        sku: "studio",
        package: "",
        variation: %{
          id: "platform"
        }
      }
    ]

  defp product_research(),
    do: [
      %ProductResearch{
        study: %{
          case_number: "1234",
          description: "Federation Study"
        }
      },
      %ProductResearch{
        study: %{
          case_number: "1235",
          description: "Studio Study"
        }
      }
    ]

  defp users(),
    do: [
      %User{
        email: "support@apollographql.com",
        name: "Jane Smith",
        total_products_created: 1337
      }
    ]
end
