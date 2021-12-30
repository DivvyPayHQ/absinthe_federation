defmodule Absinthe.Federation.Tracing.Middleware do
  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution

  # Called before resolving
  # if there isn't an `federation_tracing` flag set then we aren't actually doing any tracing
  def call(
        %Resolution{
          extensions: extensions,
          acc: %{federation_tracing_start_time: start_mono_time},
          state: :unresolved
        } = res,
        opts
      ) do
    now = System.monotonic_time(:nanosecond)
    # |> IO.inspect(label: "############## path_details")
    path_details = List.first(res.path)

    id =
      case path_details do
        idx when is_integer(idx) ->
          {:index, idx}

        %{alias: nil, name: response_name} ->
          {:response_name, response_name}

        %{alias: response_name} ->
          {:response_name, response_name}
      end

    # |> IO.inspect(label: "############## id")

    original_field_name =
      case path_details do
        %{alias: alias_name, name: name} when not is_nil(alias_name) ->
          name

        _ ->
          ""
      end

    node =
      Absinthe.Federation.Trace.Node.new(%{
        id: id,
        original_field_name: original_field_name,
        type: Absinthe.Type.name(res.definition.schema_node.type, res.schema),
        parent_type: res.parent_type.name,
        # relative to the trace's start_time, in ns
        start_time: now - start_mono_time,
        child: []
      })

    %{
      res
      | extensions: Map.put(extensions, __MODULE__, node),
        middleware: res.middleware ++ [{{__MODULE__, :after_field}, opts}]
    }
  end

  def call(res, _opts), do: res

  # Called after each resolution to calculate the end_time
  def after_field(
        %Resolution{
          state: :resolved,
          extensions: %{__MODULE__ => node} = extensions,
          acc: %{federation_tracing_start_time: start_mono_time}
        } = res,
        _opts
      ) do
    now = System.monotonic_time(:nanosecond)
    # relative to the trace's start_time, in ns
    updated_node = %{node | end_time: now - start_mono_time}

    %{res | extensions: Map.put(extensions, __MODULE__, updated_node)}
  end

  def after_field(res, _), do: res
end
