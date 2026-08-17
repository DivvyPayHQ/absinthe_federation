defmodule Products.MixProject do
  use Mix.Project

  def project do
    [
      app: :products,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: ["lib"],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  def application do
    [
      mod: {Products.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:absinthe, "~> 1.11"},
      {:absinthe_federation, path: ".."},
      {:absinthe_plug, "~> 1.5"},
      {:phoenix, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"],
      "test.compatibility": [
        "absinthe.federation.schema.sdl --schema ProductsWeb.Schema --out schema.graphql",
        "cmd npm install --silent",
        "cmd cd .. && federation_compatibility/node_modules/.bin/fedtest docker --compose federation_compatibility_docker_compose.yml --schema federation_compatibility/schema.graphql --port 4001 --failOnRequired"
      ]
    ]
  end

  defp releases,
    do: [
      server: [
        applications: [
          products: :permanent
        ],
        include_executables_for: [:unix]
      ]
    ]
end
