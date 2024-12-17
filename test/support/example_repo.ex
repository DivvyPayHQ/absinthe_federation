defmodule ExampleRepo do
  use Ecto.Repo, otp_app: :absinthe_federation, adapter: Ecto.Adapters.Postgres
end
