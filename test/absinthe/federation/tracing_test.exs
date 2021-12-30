defmodule Absinthe.Federation.TracingTests do
  use Absinthe.Federation.Case, async: true

  defmodule TestSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Tracing

    object :person do
      field(:name, :string)
      field(:age, :string)
      field(:cars, list_of(:car))
    end

    object :car do
      field(:make, non_null(:string))
      field(:model, non_null(:string))
    end

    query do
      field :get_persons, list_of(:person) do
        resolve(fn _, _ ->
          {:ok,
           [
             %{
               name: "sikan",
               age: 29,
               cars: [%{make: "Honda", model: "Civic"}]
             }
           ]}
        end)
      end
    end
  end

  test "should have :ftv1 in extensions" do
    query = """
    query {
      getPersons {
        name
        cars {
          make
          model
        }
      }
    }
    """

    %{extensions: extensions} = get_result(TestSchema, query)
    assert Map.has_key?(extensions, :ftv1)
  end

  test "alias has original_field_name set correctly" do
    query = """
    query {
      getPersons {
        personName: name
      }
    }
    """

    %{root: %{child: [%{child: [%{child: [%{child: [person_name_node]}]}]}]}} = get_decoded_trace(TestSchema, query)

    assert person_name_node.id == {:response_name, "personName"}
    assert person_name_node.original_field_name == "name"
  end

  test "sets root trace fields" do
    query = """
    query { getPersons { name } }
    """

    trace = get_decoded_trace(TestSchema, query)

    assert trace.start_time != nil
    assert trace.end_time != nil
    assert trace.duration_ns != nil
  end

  test "sets trace node fields" do
    query = """
    query { getPersons { name } }
    """

    %{root: %{child: [get_persons_trace_node]}} = get_decoded_trace(TestSchema, query)

    assert get_persons_trace_node.id == {:response_name, "getPersons"}
    assert get_persons_trace_node.start_time != nil
    assert get_persons_trace_node.end_time != nil
    assert get_persons_trace_node.parent_type == "RootQueryType"
    assert get_persons_trace_node.type == "[Person]"
  end

  test "sets list trace node children" do
    query = """
    query { getPersons { age } }
    """

    # %{root: %{child: [%{
    #         cache_policy: nil,
    #         child: [],
    #         end_time: 38_062_000,
    #         error: [
    #           %Absinthe.Federation.Trace.Error{
    #             json: "",
    #             location: [%Absinthe.Federation.Trace.Location{column: 21, line: 1}],
    #             message: "Cannot return null for non-nullable field",
    #             time_ns: 0
    #           }
    #         ],
    #         id: {:response_name, "getPersons"},
    #         original_field_name: "",
    #         parent_type: "RootQueryType",
    #         start_time: 35_654_000,
    #         type: "[Person!]"
    #       }
    #     ],
    #     end_time: 0,
    #     error: [],
    #     id: nil,
    #     original_field_name: "",
    #     parent_type: "",
    #     start_time: 0,
    #     type: ""
    #   },
    # }

    %{root: %{child: [%{child: [index_node]}]}} = get_decoded_trace(TestSchema, query)

    assert index_node.end_time == 0
    assert index_node.error == []
    assert index_node.id == {:index, 0}
    assert index_node.original_field_name == ""
    assert index_node.parent_type == ""
    assert index_node.start_time == 0
    assert index_node.type == ""
  end

  test "sets trace node error fields" do
    query = """
    query { getPersons { age } }
    """

    # %Absinthe.Federation.Trace{
    #   root: %Absinthe.Federation.Trace.Node{
    #     child: [
    #       %Absinthe.Federation.Trace.Node{
    #         child: [],
    #         end_time: 272_000,
    #         error: [
    #           %Absinthe.Federation.Trace.Error{
    #             json: "",
    #             location: [%Absinthe.Federation.Trace.Location{column: 26, line: 1}],
    #             message: "Cannot return null for non-nullable field",
    #             time_ns: 0
    #           }
    #         ],
    #         id: {:response_name, "getPersons"},
    #         original_field_name: "",
    #         parent_type: "RootQueryType",
    #         start_time: 262_000,
    #         type: "[Person!]"
    #       }
    #     ],
    #     end_time: 0,
    #     error: [],
    #     id: nil,
    #     original_field_name: "",
    #     parent_type: "",
    #     start_time: 0,
    #     type: ""
    #   },
    #   signature: "",
    #   start_time: %Google.Protobuf.Timestamp{nanos: 801_041_000, seconds: 1_642_024_406},
    #   unexecutedOperationBody: "",
    #   unexecutedOperationName: ""
    # }
    # |> IO.inspect(label: "trace")
    %{root: %{child: [%{child: [%{child: [age_node]}]}]}} = get_decoded_trace(TestSchema, query)

    assert age_node.id == {:response_name, "age"}

    assert age_node.errors == [
             %Absinthe.Federation.Trace.Error{
               json: "",
               location: [%Absinthe.Federation.Trace.Location{column: 26, line: 1}],
               message: "Cannot return null for non-nullable field",
               time_ns: 0
             }
           ]
  end

  test "does not include trace when header not present" do
    query = """
    query { getPersons { name } }
    """

    result = get_result(TestSchema, query, [])

    refute Map.has_key?(result, :extensions)
  end

  defp get_decoded_trace(schema, query, pipeline_opts \\ [context: %{apollo_federation_include_trace: "ftv1"}]) do
    schema
    |> get_result(query, pipeline_opts)
    |> Map.get(:extensions, %{})
    |> Map.get(:ftv1, "")
    |> Base.decode64!()
    |> Absinthe.Federation.Trace.decode()
  end

  defp get_result(schema, query, pipeline_opts \\ [context: %{apollo_federation_include_trace: "ftv1"}]) do
    pipeline = Absinthe.Federation.Tracing.Pipeline.default(schema, pipeline_opts)

    query
    |> Absinthe.Pipeline.run(pipeline)
    |> case do
      {:ok, %{result: result}, _} -> result
      error -> error
    end
  end
end
