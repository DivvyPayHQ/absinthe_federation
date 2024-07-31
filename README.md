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
    {:absinthe_federation, "~> 0.5"}
  ]
end
```

Install a specific branch from [GitHub](https://github.com/DivvyPayHQ/absinthe_federation):

```elixir
def deps do
  [
    {:absinthe_federation, github: "DivvyPayHQ/absinthe_federation", branch: "main"}
  ]
end
```

Use `Absinthe.Federation.Schema` module in your root schema:

```elixir
defmodule Example.Schema do
  use Absinthe.Schema
+ use Absinthe.Federation.Schema

  query do
    ...
  end
end
```

Validate everything is wired up correctly:

```bash
mix absinthe.federation.schema.sdl --schema Example.Schema
```

You should see the [Apollo Federation Subgraph Specification](https://www.apollographql.com/docs/federation/subgraph-spec) fields along with any fields you've defined. It can be helpful to add `*.graphql` to your `.gitignore`, at least at your projects root level, while testing your SDL output during development.

## Usage (macro based schemas)

The following sticks close to the Apollo Federation documentation to better clarify how to achieve the same outcomes with the `Absinthe.Federation` module as you'd get from their JavaScript examples. Note that implementing the reference resolver with function capture does not work at the moment. Hence, the examples below use an anonymous function.

### [Defining an entity](https://www.apollographql.com/docs/federation/entities#defining-an-entity)

```elixir
defmodule Products.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

  extend schema do
    directive(:link,
      url: "https://specs.apollo.dev/federation/v2.3",
      import: ["@key", ...]
    )
  end

  object :product do
    directive(:key, fields: "id")

    # Any subgraph contributing fields MUST define a _resolve_reference field.
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
    ...
  end
end
```

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

```elixir
{:ok, nil}
```

It is easier to just merge a subgraph's contributed fields back onto the incoming entity reference than rely on a struct to set the `__typename`.

### [Contributing entity fields](https://www.apollographql.com/docs/federation/entities#contributing-entity-fields)

```elixir
defmodule Inventory.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

  extend schema do
    directive(:link,
      url: "https://specs.apollo.dev/federation/v2.0",
      import: ["@key", ...]
    )
  end

  object :product do
    directive(:key, fields: "id")

    # Each subgraph MUST return unique fields, see Apollo documentation for more details.
    # Contributing to an entity does not require it to be otherwise queryable in this subgraph.
    field :_resolve_reference, :product do
      resolve(fn %{__typename: "Product", id: id} = entity, _info ->
        {:ok, Map.merge(entity, %{in_stock: true})}
      end)
    end

    field(:id, non_null(:string))
    field(:in_stock, non_null(:boolean))
  end

  query do
    ...
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
      import: ["@key", ...]
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

    # This subgraph only needs to resolve the key fields used to reference the entity.
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

### Macro based schema with existing prototype

If you are already using a schema prototype.

```elixir
defmodule Example.Schema do
  use Absinthe.Schema
+ use Absinthe.Federation.Schema, prototype_schema: Example.SchemaPrototype

  query do
    ...
  end
end
```

```elixir
defmodule Example.SchemaPrototype do
  use Absinthe.Schema.Prototype
+ use Absinthe.Federation.Schema.Prototype.FederatedDirectives

  directive :my_directive do
    on [:schema]
  end
end
```

### SDL based schemas (experimental)

```elixir
defmodule Example.Schema do
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
end
```

### Resolving structs in \_entities queries

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

### Federation v2

You can import Apollo Federation v2 directives by extending your top-level schema with the `@link` directive.

```elixir
defmodule Example.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

+ extend schema do
+   directive :link,
+     url: "https://specs.apollo.dev/federation/v2.3",
+     import: [
+       "@key",
+       "@shareable",
+       "@provides",
+       "@requires",
+       "@external",
+       "@tag",
+       "@extends",
+       "@override",
+       "@inaccessible",
+       "@composeDirective",
+       "@interfaceObject"
+     ]
+ end

  query do
    ...
  end
end
```

### Namespacing and directive renaming with `@link`

`@link` directive supports namespacing and directive renaming (only on **Absinthe >= 1.7.2**) according to the specs.

```elixir
defmodule Example.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

+ extend schema do
+   directive :link,
+     url: "https://specs.apollo.dev/federation/v2.0",
+     import: [%{"name" => "@key", "as" => "@primaryKey"}], # directive renaming
+     as: "federation" # namespacing
+ end

  query do
    ...
  end
end
```

## More Documentation

See additional documentation, including guides, in the [Absinthe.Federation hexdocs](https://hexdocs.pm/absinthe_federation).

## Contributing

Refer to the [Contributing Guide](./CONTRIBUTING.md).

## License

See [LICENSE](./LICENSE.md)

```

```
