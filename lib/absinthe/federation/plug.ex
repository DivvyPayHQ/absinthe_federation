defmodule Absinthe.Federation.Plug do
  @behaviour Plug
  import Plug.Conn

  @impl Plug
  defdelegate init(opts), to: Absinthe.Plug

  @impl Plug
  @spec call(Plug.Conn.t(), map) :: Plug.Conn.t() | no_return
  def call(conn, config) do
    config =
      conn
      |> get_req_header("apollo-federation-include-trace")
      |> case do
        [include_trace] ->
          put_in(config, [:context, :apollo_federation_include_trace], include_trace)

        _ ->
          config
      end

    Absinthe.Plug.call(conn, config)
  end
end
