defmodule Croniq.Application do
  @moduledoc """
  OTP application root and startup coordinator.

  Manages:
  - Service supervision tree
  - Database connection pooling
  - Cluster configuration
  - Scheduler initialization
  - Warm-start procedures

  Orchestrates component lifecycle and failure recovery
  for the entire system.
  """

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications

  use Application
  require Logger

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
      CroniqWeb.Endpoint,
      Croniq.Redis.Pool
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Croniq.Supervisor]
    result = Supervisor.start_link(children, opts)
    load_job_from_db()
    result
  end

  defp load_job_from_db do
    Croniq.Repo.all(Croniq.Task)
    |> Enum.each(fn task ->
      if Map.get(task, :task_type) == "delayed" do
        if task.status == "active" and is_nil(task.executed_at) do
          if not is_nil(task.scheduled_at) and
               DateTime.compare(task.scheduled_at, DateTime.utc_now()) != :gt do
            Croniq.Scheduler.execute_delayed_task(task.id)
          else
            Croniq.Scheduler.create_delayed_job(task)
          end
        end
      else
        # Обычные cron-задачи
        Croniq.Scheduler.create_quantum_job(task)
        Logger.info("Quantum job for task record id=#{task.id} created from DB on start")
      end
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
