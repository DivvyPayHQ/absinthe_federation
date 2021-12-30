defmodule Absinthe.Federation.Tracing.Pipeline.Phase.CreateTrace do
  use Absinthe.Phase

  @impl Absinthe.Phase
  def run(blueprint, options \\ [])

  def run(blueprint, options) when is_list(options),
    do: options |> Enum.into(%{}) |> run_phase(blueprint)

  def run(blueprint, _options), do: {:ok, blueprint}

  defp run_phase(
         %{context: %{apollo_federation_include_trace: "ftv1"}} = _options,
         %Absinthe.Blueprint{execution: %{acc: acc}} = blueprint
       ) do
    trace =
      Absinthe.Federation.Trace.new(%{
        # Wallclock time when the trace started.
        start_time: Absinthe.Federation.Tracing.Timestamp.now!()
      })

    new_acc =
      acc
      |> Map.put(:federation_trace, trace)
      |> Map.put(:federation_tracing_start_time, System.monotonic_time(:nanosecond))

    {:ok, put_in(blueprint.execution.acc, new_acc)}
  end

  defp run_phase(_options, blueprint), do: {:ok, blueprint}
end
