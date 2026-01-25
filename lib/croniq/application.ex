# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

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

    case Supervisor.start_link(children, opts) do
      {:ok, supervisor} ->
        Task.start(fn ->
          :timer.sleep(500)
          load_job_from_db()
        end)

        {:ok, supervisor}

      error ->
        error
    end
  end

  defp load_job_from_db do
    start_time = System.monotonic_time(:millisecond)

    tasks = Croniq.Repo.all(Croniq.Task)
    task_count = length(tasks)

    tasks
    |> Enum.each(&start_task_on_boot/1)

    duration = System.monotonic_time(:millisecond) - start_time

    # Emit boot metrics
    :telemetry.execute(
      [:croniq, :application, :boot, :load_tasks],
      %{duration: duration},
      %{}
    )

    :telemetry.execute(
      [:croniq, :application, :boot, :tasks_loaded],
      %{count: task_count},
      %{}
    )
  end

  defp start_task_on_boot(
         %{
           task_type: "delayed",
           status: "active",
           executed_at: nil,
           scheduled_at: scheduled_at,
           id: id
         } = task
       ) do
    cond do
      is_nil(scheduled_at) ->
        :noop

      DateTime.compare(scheduled_at, DateTime.utc_now()) != :gt ->
        Croniq.Scheduler.execute_delayed_task(id)

      true ->
        Croniq.Scheduler.create_delayed_job(task)
    end
  end

  defp start_task_on_boot(%{task_type: "delayed"}), do: :noop

  defp start_task_on_boot(task) do
    Croniq.Scheduler.create_quantum_job(task)
    Logger.info("Quantum job for task record id=#{task.id} created from DB on start")
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CroniqWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
