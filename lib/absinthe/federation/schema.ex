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
    pipeline
    |> Pipeline.insert_after(TypeImports, __MODULE__.Phase)
  end
end
