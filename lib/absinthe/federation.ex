defmodule Absinthe.Federation do
  @moduledoc """
  [Apollo Federation](https://www.apollographql.com/docs/federation/federation-spec/) support for [Absinthe](https://github.com/absinthe-graphql/absinthe).

  ## Examples

  Schemas should `use Absinthe.Federation.Schema`

      defmodule MyApp.MySchema do
        use Absinthe.Schema
      + use Absinthe.Federation.Schema

        query do
          ...
        end
      end

  For a type module, use `Absinthe.Federation.Notation` instead:

      defmodule MyApp.MySchema.Types do
        use Absinthe.Schema.Notation
      + use Absinthe.Federation.Notation

      end
  """

  @spec remove_federated_types_pipeline(schema :: Absinthe.Schema.t()) :: Absinthe.Pipeline.t()
  defdelegate remove_federated_types_pipeline(schema), to: Absinthe.Federation.Schema

  @spec to_federated_sdl(schema :: Absinthe.Schema.t()) :: String.t()
  defdelegate to_federated_sdl(schema), to: Absinthe.Federation.Schema
end
