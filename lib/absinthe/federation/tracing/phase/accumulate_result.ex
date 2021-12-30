defmodule Absinthe.Federation.Tracing.Pipeline.Phase.AccumulateResult do
  @moduledoc false

  alias Absinthe.Blueprint
  alias Absinthe.Blueprint.Result

  use Absinthe.Phase

  @impl Absinthe.Phase
  @spec run(Blueprint.t() | Phase.Error.t(), Keyword.t()) :: {:ok, map}
  def run(blueprint, options \\ [])

  def run(
        %Blueprint{execution: %{acc: %{federation_trace: trace, federation_tracing_start_time: start_mono_time}}} =
          blueprint,
        _options
      ) do
    now = System.monotonic_time(:nanosecond)

    duration = now - start_mono_time
    end_time = Absinthe.Federation.Tracing.Timestamp.now!()
    trace = %{trace | duration_ns: duration, end_time: end_time}
    blueprint = put_in(blueprint.execution.acc.federation_trace, trace)

    {:ok, accumulate_trace(blueprint)}
  end

  def run(blueprint, _options), do: {:ok, blueprint}

  defp accumulate_trace(
         %Blueprint{execution: %{result: %Result.Object{} = result, acc: %{federation_trace: _trace}}} = blueprint
       ) do
    # IO.inspect(result, label: "############ result")
    root_trace_node = accumulate_trace(result)
    put_in(blueprint.execution.acc.federation_trace.root, root_trace_node)
  end

  defp accumulate_trace(%Blueprint{} = blueprint), do: blueprint

  # Leaf
  defp accumulate_trace(%Result.Leaf{
         value: _,
         errors: errors,
         extensions: %{Absinthe.Federation.Tracing.Middleware => trace_node}
       }) do
    node_errors =
      Enum.map(errors, fn %{message: message, locations: locations} = _error ->
        node_error_locations =
          Enum.map(locations, fn %{line: line, column: column} ->
            Absinthe.Federation.Trace.Location.new(%{line: line, column: column})
          end)

        Absinthe.Federation.Trace.Error.new(%{
          message: message,
          location: node_error_locations,
          # TODO: Encode error in JSON string
          json: %{}
        })
      end)

    %{trace_node | error: node_errors}
  end

  # Object
  defp accumulate_trace(%Result.Object{
         fields: fields,
         extensions: %{Absinthe.Federation.Tracing.Middleware => trace_node}
       })
       when is_list(fields) do
    children = Enum.map(fields, &accumulate_trace/1)
    %{trace_node | child: children}
  end

  # List
  defp accumulate_trace(%Result.List{
         values: values,
         extensions: %{Absinthe.Federation.Tracing.Middleware => trace_node}
       })
       when is_list(values) do
    children =
      values
      |> Enum.with_index()
      |> Enum.map(fn
        {%Result.Object{fields: fields}, idx} ->
          Absinthe.Federation.Trace.Node.new(%{
            id: {:index, idx},
            child: accumulate_trace(fields)
          })

        {value, idx} ->
          Absinthe.Federation.Trace.Node.new(%{
            id: {:index, idx},
            child: List.wrap(accumulate_trace(value))
          })
      end)

    %{trace_node | child: children}
  end

  defp accumulate_trace(values) when is_list(values) do
    Enum.map(values, &accumulate_trace/1)
  end

  # Root query
  defp accumulate_trace(%Result.Object{fields: fields}) do
    children = Enum.map(fields, &accumulate_trace/1)
    Absinthe.Federation.Trace.Node.new(%{child: children})
  end
end
