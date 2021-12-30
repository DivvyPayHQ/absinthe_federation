defmodule Absinthe.Federation.PlugTest do
  use Absinthe.Federation.Case, async: true

  defmodule TestSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema
    use Absinthe.Federation.Tracing

    query do
      extends()

      # absinthe requires query to contain at least 1 root query field
      field :foo, :boolean
    end
  end

  @query """
  {
    foo
  }
  """

  test "header enables tracing" do
    opts = Absinthe.Federation.Plug.init(schema: TestSchema, pipeline: {Absinthe.Federation.Tracing.Pipeline, :plug})

    response =
      conn(:post, "/", @query)
      |> put_req_header("content-type", "application/graphql")
      |> put_req_header("apollo-federation-include-trace", "ftv1")
      |> plug_parser
      |> Absinthe.Federation.Plug.call(opts)

    assert %{status: 200, resp_body: resp_body} = response
    assert resp_body =~ "{\"data\":{\"foo\":null},\"extensions\":{\"ftv1\":\""
  end

  test "no header disables tracing" do
    opts = Absinthe.Federation.Plug.init(schema: TestSchema, pipeline: {Absinthe.Federation.Tracing.Pipeline, :plug})

    response =
      conn(:post, "/", @query)
      |> put_req_header("content-type", "application/graphql")
      |> plug_parser
      |> Absinthe.Federation.Plug.call(opts)

    assert %{status: 200, resp_body: resp_body} = response
    assert ~s({"data":{"foo":null}}) == resp_body
  end
end
