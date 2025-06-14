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
      {:phoenix, "== 1.7.21"},
      {:phoenix_ecto, "== 4.6.4"},
      {:ecto_sql, "== 3.12.1"},
      {:postgrex, "== 0.20.0"},
      {:phoenix_html, "== 4.2.1"},
      {:phoenix_live_view, "== 1.0.17"},
      {:phoenix_live_dashboard, "== 0.8.7"},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.2.0",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "== 1.19.2"},
      {:finch, "== 0.19.0"},
      {:telemetry_metrics, "== 1.1.0"},
      {:telemetry_poller, "== 1.2.0"},
      {:gettext, "== 0.26.2"},
      {:jason, "== 1.4.4"},
      {:dns_cluster, "== 0.2.0"},
      {:bandit, "== 1.7.0"},
      {:bcrypt_elixir, "== 3.3.2"},
      {:guardian, "== 2.3.2"},
      {:quantum, "== 3.5.3"},
      {:crontab, "== 1.1.14"},
      {:httpoison, "== 2.2.3"},
      # Dev/test dependencies
      {:phoenix_live_reload, "== 1.6.0", only: :dev},
      {:esbuild, "== 0.10.0", runtime: Mix.env() == :dev},
      {:tailwind, "== 0.3.1", runtime: Mix.env() == :dev},
      {:floki, "== 0.38.0", only: :test},
      {:credo, "== 1.7.12", only: :dev},
      {:recode, "== 0.7.3", only: :dev}
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
