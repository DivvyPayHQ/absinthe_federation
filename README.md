# Absinthe.Federation

[![Build Status](https://github.com/DivvyPayHQ/absinthe_federation/workflows/CI/badge.svg)](https://github.com/DivvyPayHQ/absinthe_federation/actions?query=workflow%3ACI)
[![Hex pm](https://img.shields.io/hexpm/v/absinthe_federation.svg)](https://hex.pm/packages/absinthe_federation)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/absinthe_federation/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[Apollo Federation](https://www.apollographql.com/docs/federation) support for [Absinthe](https://hexdocs.pm/absinthe/overview.html).

## Installation

Install from [Hex](https://hex.pm/packages/absinthe_federation):

```elixir
def deps do
  [
    {:absinthe, "~> 1.7"},
    {:absinthe_federation, "~> 0.5"}
  ]
end
```

Install a specific branch from [GitHub](https://github.com/DivvyPayHQ/absinthe_federation):

```elixir
def deps do
  [
    {:absinthe, "~> 1.7"},
    {:absinthe_federation, github: "DivvyPayHQ/absinthe_federation", branch: "main"}
  ]
end
```

Use `Absinthe.Federation.Schema` module in your root schema:

```elixir
defmodule Example.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

  query do
  end
end
```

Validate everything is wired up correctly:

```bash
mix absinthe.federation.schema.sdl --schema Example.Schema
```

You should see the [Apollo Federation Subgraph Specification](https://www.apollographql.com/docs/federation/subgraph-spec) fields along with any fields you've defined. It can be helpful to add `*.graphql` to your `.gitignore`, at least at your projects root level, while testing your SDL output during development.

## Usage

The following sticks close to the Apollo Federation documentation to better clarify how to achieve the same outcomes with the `Absinthe.Federation` module as you'd get from their JavaScript examples.

### [Defining an entity](https://www.apollographql.com/docs/federation/entities#defining-an-entity)

```elixir
defmodule Products.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

  extend schema do
    directive(:link,
      url: "https://specs.apollo.dev/federation/v2.0",
      import: ["@key"]
    )
  end

  object :product do
    directive(:key, fields: "id")

    # Any subgraph contributing fields MUST defined a resolve reference.
    field(:_resolve_reference, :product) do
      resolve(fn %{__typename: "Product", id: id} = entity, _info ->
        {:ok, Map.merge(entity, %{name: "ACME Anvil", price: 10000})}
      end)
    end

    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:price, :int)
  end

  query do
  end
end
```

~~The `:_resolve_reference` version of the `resolve/1` method will receive a 2 arity function. The first argument is an entity representation and the second the `Absinthe.Resolution.t()`.~~

Your `:_resolve_reference` must return one of the follow:

```elixir
{:ok, %Product{id: id, ...}}
```

```elixir
{:ok, %{__typename: "Product", id: id, ...}}
```

```elixir
{:ok, %{"__typename" => "Product", "id" => id, ...}}
```

### [Contributing entity fields](https://www.apollographql.com/docs/federation/entities#contributing-entity-fields)

```elixir
defmodule Inventory.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

  extend schema do
    directive(:link,
      url: "https://specs.apollo.dev/federation/v2.0",
      import: ["@key"]
    )
  end

  object :product do
    directive(:key, fields: "id")

    # Each subgraph MUST return unique fields, see Apollo documentation for more details.
    field :_resolve_reference, :product do
      resolve(fn %{__typename: "Product", id: id} = entity, _info ->
        {:ok, Map.merge(entity, %{in_stock: true})}
      end)
    end

    field(:id, non_null(:string))
    field(:in_stock, non_null(:boolean))
  end

  query do
  end
end
```

### [Referencing an entity without contributing fields](https://www.apollographql.com/docs/federation/entities#referencing-an-entity-without-contributing-fields)

```elixir
defmodule Reviews.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

  extend schema do
    directive(:link,
      url: "https://specs.apollo.dev/federation/v2.0",
      import: ["@key"]
    )
  end

  # Stubbed entity, marked as unresolvable in this subgraph.
  object :product do
    directive(:key, fields: "id", resolvable: false)

    field(:id, non_null(:string))
  end

  object :review do
    field(:id, non_null(:id))
    field(:score, non_null(:int))
    field(:description, non_null(:string))

    # This subgraph need only resolve the key fields used to reference the entity.
    field(:product, non_null(:product)) do
      resolve(fn %{product_id: id} = _parent, _args, _info ->
        {:ok, %{id: id}}
      end)
    end
  end

  query do
    field(:latest_reviews, non_null(list(:review))) do
      resolve(fn args, info ->
        case Reviews.find_many(args, info) do
          {:ok, _reviews} = results ->
            results

          {:error, _reason} = error ->
            error
        end
      end)
    end
  end
end
```
