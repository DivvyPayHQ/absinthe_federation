# Absinthe.Federation

[![Build Status](https://github.com/DivvyPayHQ/absinthe_federation/workflows/CI/badge.svg)](https://github.com/DivvyPayHQ/absinthe_federation/actions?query=workflow%3ACI)
[![Hex pm](http://img.shields.io/hexpm/v/absinthe_federation.svg)](https://hex.pm/packages/absinthe_federation)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/absinthe_federation/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[Apollo Federation](https://www.apollographql.com/docs/federation/federation-spec/) support for [Absinthe](https://github.com/absinthe-graphql/absinthe)

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe_federation):

```elixir
def deps do
  [
    {:absinthe_federation, "~> 0.1.9"}
  ]
end
```

Install from github:

```elixir
def deps do
  [
    {:absinthe_federation, github: "DivvyPayHQ/absinthe_federation", branch: "main"}
  ]
end
```

Add the following line to your absinthe schema

```elixir
defmodule MyApp.MySchema do
  use Absinthe.Schema
+ use Absinthe.Federation.Schema

  query do
    ...
  end
end
```

## Usage

### Macro based schemas (recommended)

```elixir
defmodule MyApp.MySchema do
  use Absinthe.Schema
+ use Absinthe.Federation.Schema

  query do
+   extends()

    field :review, :review do
      arg(:id, non_null(:id))
      resolve(&ReviewResolver.get_review_by_id/3)
    end
    ...
  end

  object :product do
+   key_fields("upc")
+   extends()

    field :upc, non_null(:string) do
+     external()
    end

    field(:reviews, list_of(:review)) do
      resolve(&ReviewResolver.get_reviews_for_product/3)
    end

+   field(:_resolve_reference, :product) do
+     resolve(&ProductResolver.get_product_by_upc/3)
+   end
  end
end
```

### SDL based schemas (experimental)

```elixir
defmodule MyApp.MySchema do
  use Absinthe.Schema
+ use Absinthe.Federation.Schema

  import_sdl """
    extend type Query {
      review(id: ID!): Review
    }

    extend type Product @key(fields: "upc") {
      upc: String! @external
      reviews: [Review]
    }
  """

  def hydrate(_, _) do
    ...
  end
```

### Resolving structs in _entities queries

If you need to resolve your struct to a specific type in your schema you can implement the `Absinthe.Federation.Schema.EntityUnion.Resolver` protocol like this:

```elixir
defmodule MySchema do
  @type t :: %__MODULE__{
          id: String.t()
        }

  defstruct id: ""

  defimpl Absinthe.Federation.Schema.EntityUnion.Resolver do
    def resolve_type(_, _), do: :my_schema_object_name
  end
end
```

## More Documentation

See additional documentation, including guides, in the [Absinthe.Federation hexdocs](https://hexdocs.pm/absinthe_federation).

## Contributing

Refer to the [Contributing Guide](./CONTRIBUTING.md).

## License

See [LICENSE](./LICENSE.md)
