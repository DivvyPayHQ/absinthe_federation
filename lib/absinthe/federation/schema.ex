defmodule Absinthe.Federation.Schema do
  @moduledoc false

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

  def pipeline(pipeline) do
    pipeline
    |> Pipeline.insert_after(TypeImports, __MODULE__.Phase)
  end
end
