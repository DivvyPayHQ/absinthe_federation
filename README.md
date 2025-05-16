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
    {:absinthe_federation, "~> 0.7"}
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

The following sticks close to the Apollo Federation documentation to better clarify how to achieve the same outcomes with the `Absinthe.Federation` module as you'd get from their JavaScript examples.

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
    directive :key, fields: "id"

    # Any subgraph contributing fields MUST define a _resolve_reference field.
    field :_resolve_reference, :product do
      resolve &Products.find_by_id/2
    end

    field :id, non_null(:id)
    field :name, non_null(:string)
    field :price, :int
  end

  query do
    ...
  end
end
```

Your `:_resolve_reference` must return one of the following:

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

Each subgraph, by default, must return different fields. See the Apollo documentation should you need to [override this behavior](https://www.apollographql.com/docs/federation/entities/resolve-another-subgraphs-fields).

```elixir
defmodule Inventory.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

  extend schema do
    directive(:link,
      url: "https://specs.apollo.dev/federation/v2.3",
      import: ["@key", ...]
    )
  end

  object :product do
    directive :key, fields: "id"

    # In this case, only the `Inventory.Schema` should resolve the `inStock` field.
    field :_resolve_reference, :product do
      resolve(fn %{__typename: "Product", id: id} = entity, _info ->
        {:ok, Map.merge(entity, %{in_stock: true})}
      end)
    end

    field :id, non_null(:string)
    field :in_stock, non_null(:boolean)
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
      url: "https://specs.apollo.dev/federation/v2.3",
      import: ["@key", ...]
    )
  end

  # Stubbed entity, marked as unresolvable in this subgraph.
  object :product do
    directive :key, fields: "id", resolvable: false

    field :id, non_null(:string)
  end

  object :review do
    field :id, non_null(:id)
    field :score, non_null(:int)
    field :description, non_null(:string)

    # This subgraph only needs to resolve the key fields used to reference the entity.
    field :product, non_null(:product) do
      resolve(fn %{product_id: id} = _parent, _args, _info ->
        {:ok, %{id: id}}
      end)
    end
  end

  query do
    field :latest_reviews, non_null(list(:review)) do
      resolve(&ReviewsResolver.find_many/2)
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

### Using Dataloader in \_resolve_reference queries

You can use Dataloader in to resolve references to specific objects, but it requires manually setting up the batch and item key, as the field has no parent. Resolution for both \_resolve_reference fields are functionally equivalent.

```elixir
defmodule Example.Schema do
  use Absinthe.Schema
  use Absinthe.Federation.Schema

  import Absinthe.Resolution.Helpers, only: [on_load: 2, dataloader: 2]

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(Example.Loader, Dataloader.Ecto.new(Example.Repo))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  object :item do
    key_fields("item_id")

    # Using the dataloader/2 resolution helper
    field :_resolve_reference, :item do
      resolve dataloader(Example.Loader, fn _parent, args, _res ->
                %{batch: {{:one, Example.Item}, %{}}, item: [item_id: args.item_id]}
              end)
    end
  end

  object :verbose_item do
    key_fields("item_id")

    # Using the on_load/2 resolution helper
    field :_resolve_reference, :verbose_item do
      resolve fn %{item_id: id}, %{context: %{loader: loader}} ->
        batch_key = {:one, Example.Item, %{}}
        item_key = [item_id: id]

        loader
        |> Dataloader.load(Example.Loader, batch_key, item_key)
        |> on_load(fn loader ->
          result = Dataloader.get(loader, Example.Loader, batch_key, item_key)
          {:ok, result}
        end)
    end
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
+     url: "https://specs.apollo.dev/federation/v2.7",
+     import: [
        "@authenticated",
        "@extends",
        "@external",
        "@inaccessible",
        "@key",
        "@override",
        "@policy",
        "@provides",
        "@requires",
        "@requiresScopes",
        "@shareable",
        "@tag",
        "@composeDirective",
        "@interfaceObject"
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
+     url: "https://specs.apollo.dev/federation/v2.3",
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
