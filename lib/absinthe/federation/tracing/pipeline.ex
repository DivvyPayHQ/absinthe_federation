defmodule Absinthe.Federation.Tracing.Pipeline do
  alias Absinthe.Federation.Tracing

  def default(schema, pipeline_opts \\ []) do
    schema
    |> Absinthe.Pipeline.for_document(pipeline_opts)
    |> add_phases(pipeline_opts)
  end

  if Code.ensure_loaded?(Absinthe.Plug) do
    def plug(config, pipeline_opts \\ []) do
      config
      |> Absinthe.Plug.default_pipeline(pipeline_opts)
      |> add_phases(pipeline_opts)
    end
  end

  def add_phases(pipeline, pipeline_opts) do
    pipeline
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Blueprint,
      {Tracing.Pipeline.Phase.CreateTrace, pipeline_opts}
    )
    |> Absinthe.Pipeline.insert_before(
      Absinthe.Phase.Document.Result,
      Tracing.Pipeline.Phase.AccumulateResult
    )
    |> Absinthe.Pipeline.insert_after(
      Absinthe.Phase.Document.Result,
      Tracing.Pipeline.Phase.AddExtension
    )
  end
end
