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
  def remove_federated_types_pipeline(schema) do
    schema
    |> Absinthe.Pipeline.for_schema(prototype_schema: schema.__absinthe_prototype_schema__())
    |> Absinthe.Pipeline.upto({Absinthe.Phase.Schema.Validation.Result, pass: :final})
    |> Absinthe.Schema.apply_modifiers(schema)
    |> Absinthe.Pipeline.without(__MODULE__.Schema.Phase.AddFederatedTypes)
    |> Absinthe.Pipeline.insert_before(
      Absinthe.Phase.Schema.ApplyDeclaration,
      __MODULE__.Schema.Phase.RemoveResolveReferenceFields
    )
  end

  @spec to_federated_sdl(schema :: Absinthe.Schema.t()) :: String.t()
  def to_federated_sdl(schema) do
    pipeline = remove_federated_types_pipeline(schema)

    # we can be assertive here, since this same pipeline was already used to
    # successfully compile the schema.
    {:ok, bp, _} = Absinthe.Pipeline.run(schema.__absinthe_blueprint__(), pipeline)

    Absinthe.Schema.Notation.SDL.Render.inspect(bp, %{pretty: true})
  end
end
