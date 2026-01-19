# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule Croniq.MixProject do
  use Mix.Project

  def project do
    [
      app: :croniq,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Croniq.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "== 1.8.3"},
      {:phoenix_ecto, "== 4.7.0"},
      {:ecto_sql, "== 3.13.4"},
      {:postgrex, "== 0.22.0"},
      {:phoenix_html, "== 4.3.0"},
      {:phoenix_live_view, "== 1.1.20"},
      {:phoenix_live_dashboard, "== 0.8.7"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "== 1.20.1"},
      {:finch, "== 0.20.0"},
      {:telemetry_metrics, "== 1.1.0"},
      {:telemetry_poller, "== 1.3.0"},
      {:gettext, "== 1.0.2"},
      {:jason, "== 1.4.4"},
      {:dns_cluster, "== 0.2.0"},
      {:bandit, "== 1.10.1"},
      {:bcrypt_elixir, "== 3.3.2"},
      {:guardian, "== 2.4.0"},
      {:quantum, "== 3.5.3"},
      {:crontab, "== 1.2.0"},
      {:httpoison, "== 2.3.0"},
      {:redix, "== 1.5.3"},
      {:poolboy, "== 1.5.2"},
      # Dev/test dependencies
      {:phoenix_live_reload, "== 1.6.2", only: :dev},
      {:esbuild, "== 0.10.0", runtime: Mix.env() == :dev},
      {:tailwind, "== 0.4.1", runtime: Mix.env() == :dev},
      {:floki, "== 0.38.0", only: :test},
      {:credo, "== 1.7.15", only: :dev},
      {:recode, "== 0.8.0", only: :dev},
      {:mox, "== 1.2.0", only: :test}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind croniq", "esbuild croniq"],
      "assets.deploy": [
        "tailwind croniq --minify",
        "esbuild croniq --minify",
        "phx.digest"
      ]
    ]
  end
end
