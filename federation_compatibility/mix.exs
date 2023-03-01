defmodule Products.MixProject do
  use Mix.Project

  def project do
    [
      app: :products,
      version: "0.1.0",
      elixir: "~> 1.10",
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
      {:absinthe, "~> 1.7.1"},
      {:absinthe_federation, path: ".."},
      {:absinthe_plug, "~> 1.5"},
      {:phoenix, "~> 1.7"},
      {:jason, "~> 1.4"},
      {:plug_cowboy, "~> 2.6"}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get"]
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
