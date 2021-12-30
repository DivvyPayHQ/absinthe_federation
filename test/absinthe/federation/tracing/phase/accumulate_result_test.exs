defmodule Absinthe.Federation.Tracing.Pipeline.Phase.AccumulateResultTest do
  use Absinthe.Federation.Case

  alias Absinthe.Federation.Tracing.Pipeline.Phase.AccumulateResult

  setup do
    start_trace = Absinthe.Federation.Trace.new(%{})
    start_mono_time = System.monotonic_time(:nanosecond)

    blueprint = %Absinthe.Blueprint{
      execution: %Absinthe.Blueprint.Execution{
        acc: %{federation_trace: start_trace, federation_tracing_start_time: start_mono_time}
      }
    }

    {:ok, blueprint: blueprint}
  end

  describe "trace root" do
    test "sets a duration_ns", %{blueprint: blueprint} do
      {:ok, updated_blueprint} = AccumulateResult.run(blueprint)
      assert updated_blueprint.execution.acc.federation_trace.duration_ns != nil
    end

    test "sets an end_time", %{blueprint: blueprint} do
      {:ok, updated_blueprint} = AccumulateResult.run(blueprint)
      assert updated_blueprint.execution.acc.federation_trace.end_time != nil
    end
  end
end
