# The MIT License (MIT).
#
# Copyright (c) 2025 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

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
    |> Enum.each(&start_task_on_boot/1)
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
