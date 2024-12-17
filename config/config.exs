import Config

config :absinthe_federation, ecto_repos: [ExampleRepo]

config :absinthe_federation, ExampleRepo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "example_test",
  hostname: "localhost",
  pool_size: 20,
  pool: Ecto.Adapters.SQL.Sandbox,
  log: :info
