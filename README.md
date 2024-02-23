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
    {:absinthe_federation, "~> 0.5"}
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

> Note: Implementing the reference resolver with function capture does not work at the moment. Hence, the below example uses an anonymous function.

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
+     resolve(fn parent, args, context ->
        ProductResolver.get_product_by_upc(parent, args, context)
      end)
+   end
  end
end
```

### Macro based schema with existing prototype

If you are already using a schema prototype

```elixir
defmodule MyApp.MySchema do
  use Absinthe.Schema
+ use Absinthe.Federation.Schema, prototype_schema: MyApp.MySchemaPrototype

  query do
    ...
  end
end
```

```elixir
defmodule MyApp.MySchemaPrototype do
  use Absinthe.Schema.Prototype
+ use Absinthe.Federation.Schema.Prototype.FederatedDirectives

  directive :my_directive do
    on [:schema]
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
defmodule MyApp.MySchema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

+ extend schema do
+   directive :link,
+     url: "https://specs.apollo.dev/federation/v2.0",
+     import: [
+       "@key",
+       "@shareable",
+       "@provides",
+       "@external",
+       "@tag",
+       "@extends",
+       "@override",
+       "@inaccessible"
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
defmodule MyApp.MySchema do
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
