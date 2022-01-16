defmodule Absinthe.Federation.Schema do
  @moduledoc """
  Module for injecting custom `Absinthe.Phase`s for adding federated types and directives.

  ## Example

      defmodule MyApp.MySchema do
        use Absinthe.Schema
      + use Absinthe.Federation.Schema

        query do
          ...
        end
      end
  """

  alias Absinthe.Phase.Schema.TypeImports
  alias Absinthe.Pipeline

  defmacro __using__(opts) do
    do_using(opts)
  end

  defp do_using(_opts) do
    quote do
      @pipeline_modifier unquote(__MODULE__)
      @prototype_schema Absinthe.Federation.Schema.Prototype

      use Absinthe.Federation.Notation
      import_types Absinthe.Federation.Types
    end
  end

  @doc """
  Injects custom compile-time `Absinthe.Phase`
  """
  def pipeline(pipeline) do
    Pipeline.insert_after(pipeline, TypeImports, [
      __MODULE__.Phase.AddFederatedTypes,
      __MODULE__.Phase.AddFederatedDirectives,
      __MODULE__.Phase.Validation.KeyFieldsMustBeExist,
      __MODULE__.Phase.Validation.KeyFieldsMustBeValidWhenExtends
    ])
  end

  @spec remove_federated_types_pipeline(schema :: Absinthe.Schema.t()) :: Absinthe.Pipeline.t()
  def remove_federated_types_pipeline(schema) do
    schema
    |> Absinthe.Pipeline.for_schema(prototype_schema: schema.__absinthe_prototype_schema__())
    |> Absinthe.Pipeline.upto({Absinthe.Phase.Schema.Validation.Result, pass: :final})
    |> Absinthe.Schema.apply_modifiers(schema)

    # TODO: Due to an issue found with rendering the SDL we had to revert this functionality
    # https://github.com/DivvyPayHQ/absinthe_federation/issues/28
    # |> Absinthe.Pipeline.without(__MODULE__.Phase.AddFederatedTypes)
    # |> Absinthe.Pipeline.insert_before(
    #   Absinthe.Phase.Schema.ApplyDeclaration,
    #   __MODULE__.Phase.RemoveResolveReferenceFields
    # )
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
