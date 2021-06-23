# Absinthe.Federation

[![Build Status](https://github.com/DivvyPayHQ/absinthe_federation/workflows/CI/badge.svg)](https://github.com/DivvyPayHQ/absinthe_federation/actions?query=workflow%3ACI)
[![Hex pm](http://img.shields.io/hexpm/v/absinthe.svg)](https://hex.pm/packages/absinthe_federation)
[![Hex Docs](https://img.shields.io/badge/hex-docs-blue.svg)](https://hexdocs.pm/absinthe_federation/)
[![License](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)

[Apollo Federation](https://www.apollographql.com/docs/federation/federation-spec/) support for [Absinthe](https://github.com/absinthe-graphql/absinthe)

## Installation

Install from [Hex.pm](https://hex.pm/packages/absinthe_federation):

```elixir
def deps do
  [
    {:absinthe_federation, "~> 0.1.0"}
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

## More Documentation

See additional documentation, including guides, in the [Absinthe.Federation hexdocs](https://hexdocs.pm/absinthe_federation).

## Contributing

Refer to the [Contributing Guide](./CONTRIBUTING.md).

## License

See [LICENSE](./LICENSE.md)
