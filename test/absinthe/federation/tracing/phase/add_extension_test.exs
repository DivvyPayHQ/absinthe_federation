defmodule Absinthe.Federation.Tracing.Pipeline.Phase.AddExtensionTest do
  use Absinthe.Federation.Case

  alias Absinthe.Federation.Tracing.Pipeline.Phase.AddExtension

  @decoded_trace %Absinthe.Federation.Trace{
    duration_ns: 8_344_442,
    end_time: %Google.Protobuf.Timestamp{nanos: 118_000_000, seconds: 1_642_025_470},
    root: %Absinthe.Federation.Trace.Node{
      child: [
        %Absinthe.Federation.Trace.Node{
          child: [
            %Absinthe.Federation.Trace.Node{
              child: [
                %Absinthe.Federation.Trace.Node{
                  end_time: 6_689_951,
                  id: {:response_name, "name"},
                  parent_type: "Person",
                  start_time: 6_610_044,
                  type: "String"
                },
                %Absinthe.Federation.Trace.Node{
                  end_time: 6_744_091,
                  error: [
                    %Absinthe.Federation.Trace.Error{
                      json:
                        "{\"message\":\"Cannot return null for non-nullable field Person.age.\",\"locations\":[{\"line\":1,\"column\":22}],\"path\":[\"getPerson\",0,\"age\"]}",
                      location: [
                        %Absinthe.Federation.Trace.Location{column: 22, line: 1}
                      ],
                      message: "Cannot return null for non-nullable field Person.age."
                    }
                  ],
                  id: {:response_name, "age"},
                  parent_type: "Person",
                  start_time: 6_717_259,
                  type: "Int!"
                }
              ],
              id: {:index, 0}
            }
          ],
          end_time: 6_544_360,
          id: {:response_name, "getPerson"},
          parent_type: "Query",
          start_time: 5_994_485,
          type: "[Person!]"
        }
      ]
    },
    start_time: %Google.Protobuf.Timestamp{nanos: 110_000_000, seconds: 1_642_025_470}
  }
  @encoded_trace "GgsI/qP9jgYQgJOiOCILCP6j/Y4GEIDvuTRY+qb9A3K5AmK2AgoJZ2V0UGVyc29uGglbUGVyc29uIV1A9e/tAkjot48DYowCEABiIAoEbmFtZRoGU3RyaW5nQPy4kwNIn6mYA2oGUGVyc29uYuUBCgNhZ2UaBEludCFAy/6ZA0ib0JsDWsUBCjVDYW5ub3QgcmV0dXJuIG51bGwgZm9yIG5vbi1udWxsYWJsZSBmaWVsZCBQZXJzb24uYWdlLhIECAEQFiKFAXsibWVzc2FnZSI6IkNhbm5vdCByZXR1cm4gbnVsbCBmb3Igbm9uLW51bGxhYmxlIGZpZWxkIFBlcnNvbi5hZ2UuIiwibG9jYXRpb25zIjpbeyJsaW5lIjoxLCJjb2x1bW4iOjIyfV0sInBhdGgiOlsiZ2V0UGVyc29uIiwwLCJhZ2UiXX1qBlBlcnNvbmoFUXVlcnk="

  setup do
    blueprint = %Absinthe.Blueprint{execution: %Absinthe.Blueprint.Execution{acc: %{federation_trace: @decoded_trace}}}

    {:ok, blueprint: blueprint}
  end

  test "sets the result.extensions.ftv1 field with a base64 encoded trace", %{blueprint: blueprint} do
    {:ok, updated_blueprint} = AddExtension.run(blueprint)

    assert updated_blueprint.result.extensions.ftv1 == @encoded_trace
  end

  test "does not set result.extensions.ftv1 if no trace was created" do
    blueprint = %Absinthe.Blueprint{}

    {:ok, %{result: result}} = AddExtension.run(blueprint)

    refute Map.has_key?(result, :extensions)
  end
end
