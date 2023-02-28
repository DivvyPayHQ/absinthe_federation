# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

# Configures the endpoint
config :products, ProductsWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "yequbstbYE3Kqe8tlL+AF0loLHcFZxQo5VLN7eoSyR6BKsIMoRS8LQY8cOFr68mu",
  render_errors: [view: ProductsWeb.ErrorView, accepts: ~w(json), layout: false],
  pubsub_server: Products.PubSub,
  live_view: [signing_salt: "JDViTmQG"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
