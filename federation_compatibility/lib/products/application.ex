defmodule Products.Application do
  use Application

  def start(_type, _args) do
    children = [ProductsWeb.Endpoint]

    opts = [strategy: :one_for_one, name: Products.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    ProductsWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
