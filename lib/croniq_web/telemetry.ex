# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller will execute the given period measurements
      # every 10_000ms. Learn more here: https://hexdocs.pm/telemetry_metrics
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.start.system_time",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.start.system_time",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.exception.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),
      summary("phoenix.socket_connected.duration",
        unit: {:native, :millisecond}
      ),
      sum("phoenix.socket_drain.count"),
      summary("phoenix.channel_joined.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.channel_handled_in.duration",
        tags: [:event],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("croniq.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("croniq.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("croniq.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("croniq.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("croniq.repo.query.idle_time",
        unit: {:native, :millisecond},
        description:
          "The time the connection spent waiting before being checked out for the query"
      ),
      counter("croniq.repo.query.count",
        tags: [:query_type],
        description: "Number of database queries"
      ),
      counter("croniq.repo.error.count",
        tags: [:error_type],
        description: "Number of database errors"
      ),

      # HTTP Request Metrics
      summary("croniq.request.duration",
        unit: {:native, :millisecond},
        tags: [:task_id, :method, :status_code],
        description: "HTTP request execution duration"
      ),
      counter("croniq.request.success.count",
        tags: [:task_id, :status_code],
        description: "Number of successful HTTP requests"
      ),
      counter("croniq.request.error.count",
        tags: [:task_id, :error_type],
        description: "Number of failed HTTP requests"
      ),
      summary("croniq.request.request_size",
        unit: {:byte, :byte},
        tags: [:task_id],
        description: "HTTP request body size"
      ),
      summary("croniq.request.response_size",
        unit: {:byte, :byte},
        tags: [:task_id, :status_code],
        description: "HTTP response body size"
      ),
      counter("croniq.request.status_code.count",
        tags: [:status_code, :task_id],
        description: "HTTP status code distribution"
      ),
      counter("croniq.request.client_error.count",
        tags: [:status_code],
        description: "Number of 4xx HTTP errors"
      ),
      counter("croniq.request.server_error.count",
        tags: [:status_code],
        description: "Number of 5xx HTTP errors"
      ),
      counter("croniq.request.timeout.count",
        tags: [:task_id],
        description: "Number of request timeouts"
      ),

      # Scheduler Metrics
      last_value("croniq.scheduler.jobs.count",
        description: "Total number of scheduled jobs"
      ),
      last_value("croniq.scheduler.active_jobs.count",
        description: "Number of active scheduled jobs"
      ),
      counter("croniq.scheduler.jobs.executed.count",
        tags: [:task_type],
        description: "Number of executed jobs"
      ),
      counter("croniq.scheduler.jobs.missed.count",
        description: "Number of missed job executions"
      ),

      # Task Type Metrics
      last_value("croniq.tasks.count",
        tags: [:task_type, :status],
        description: "Number of tasks by type and status"
      ),
      counter("croniq.tasks.delayed.executed.count",
        description: "Number of executed delayed tasks"
      ),
      counter("croniq.tasks.recurring.executed.count",
        description: "Number of executed recurring tasks"
      ),

      # Limits Metrics
      counter("croniq.limits.exceeded.count",
        tags: [:user_id],
        description: "Number of times request limit was exceeded"
      ),
      last_value("croniq.limits.usage.requests_today",
        tags: [:user_id],
        description: "Number of requests made today by user"
      ),
      counter("croniq.limits.notifications.sent.count",
        tags: [:user_id],
        description: "Number of limit exceeded notifications sent"
      ),

      # Redis Metrics
      summary("croniq.redis.command.duration",
        unit: {:native, :millisecond},
        tags: [:command],
        description: "Redis command execution duration"
      ),
      counter("croniq.redis.error.count",
        tags: [:error_type],
        description: "Number of Redis errors"
      ),
      last_value("croniq.redis.pool.available_workers",
        description: "Number of available Redis pool workers"
      ),

      # Application Boot Metrics
      summary("croniq.application.boot.load_tasks.duration",
        unit: {:native, :millisecond},
        description: "Time to load tasks on application boot"
      ),
      last_value("croniq.application.boot.tasks_loaded.count",
        description: "Number of tasks loaded on boot"
      ),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      {__MODULE__, :measure_task_counts, []},
      {__MODULE__, :measure_scheduler_jobs, []},
      {__MODULE__, :measure_redis_pool, []}
    ]
  end

  def measure_task_counts do
    alias Croniq.Repo
    alias Croniq.Task
    import Ecto.Query

    # Count tasks by type and status
    task_types = ["recurring", "delayed"]
    statuses = ["active", "completed", "inactive"]

    for task_type <- task_types, status <- statuses do
      count =
        Task
        |> where([t], t.task_type == ^task_type and t.status == ^status)
        |> Repo.aggregate(:count, :id)

      :telemetry.execute(
        [:croniq, :tasks],
        %{count: count},
        %{task_type: task_type, status: status}
      )
    end
  end

  def measure_scheduler_jobs do
    alias Croniq.Repo
    alias Croniq.Task
    import Ecto.Query

    total_tasks = Repo.aggregate(Task, :count, :id)
    active_tasks = Repo.aggregate(from(t in Task, where: t.status == "active"), :count, :id)

    :telemetry.execute(
      [:croniq, :scheduler, :jobs],
      %{count: total_tasks},
      %{}
    )

    :telemetry.execute(
      [:croniq, :scheduler, :active_jobs],
      %{count: active_tasks},
      %{}
    )
  end

  def measure_redis_pool do
    try do
      pool_name = :redix_pool
      pool_size = :poolboy.info(pool_name, :size)
      pool_workers = :poolboy.info(pool_name, :workers)
      available_workers = length(pool_workers)

      :telemetry.execute(
        [:croniq, :redis, :pool, :available_workers],
        %{count: available_workers},
        %{}
      )
    rescue
      _ -> :ok
    end
  end
end
