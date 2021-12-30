defmodule Absinthe.Federation.Tracing.Pipeline.Phase.AddExtension do
  use Absinthe.Phase

  require Logger

  @impl Absinthe.Phase
  def run(blueprint, options \\ [])

  def run(%Absinthe.Blueprint{result: result, execution: %{acc: %{federation_trace: trace}}} = blueprint, _options) do
    encoded_trace =
      trace
      |> Absinthe.Federation.Trace.encode()
      |> Base.encode64()

    extensions =
      result
      |> Map.get(:extensions, %{})
      |> Map.put(:ftv1, encoded_trace)

    result = Map.put(result, :extensions, extensions)

    {:ok, %{blueprint | result: result}}
  end

  def run(blueprint, _options), do: {:ok, blueprint}
end
