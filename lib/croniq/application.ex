defmodule Croniq.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  import Logger

  @impl true
  def start(_type, _args) do
    children = [
      CroniqWeb.Telemetry,
      Croniq.Repo,
      {DNSCluster, query: Application.get_env(:croniq, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Croniq.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Croniq.Finch},
      # Start a worker by calling: Croniq.Worker.start_link(arg)
      # {Croniq.Worker, arg},
      Croniq.Scheduler,
      # Start to serve requests, typically the last entry
      CroniqWeb.Endpoint,
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Croniq.Supervisor]
    result = Supervisor.start_link(children, opts)
    IO.inspect(result)
    load_job_from_db()
    result
  end

  defp load_job_from_db() do
    Croniq.Repo.all(Croniq.Task)
    |> Enum.each(fn task ->
      Croniq.Scheduler.create_quantum_job(task)
      Logger.info("Quantum job for task record id=#{task.id} created from DB on start")
    end)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CroniqWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
