# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule Croniq.Scheduler do
  @moduledoc """
  Quantum scheduler integration layer.

  Responsibilities:
  - Creating/updating cron jobs from task definitions
  - Managing job lifecycle (activation/deactivation)
  - Bridging between database and scheduler process
  - Ensuring job/task synchronization

  Translates task schedules into Quantum job configurations
  and maintains runtime consistency.
  """
  use Quantum, otp_app: :croniq_scheduler
  require Logger

  def create_quantum_job(task) do
    parsed_cron = Crontab.CronExpression.Parser.parse!(task.schedule)
    job_name = String.to_atom("request_by_task_#{task.id}")

    Croniq.Scheduler.new_job()
    |> Quantum.Job.set_name(job_name)
    |> Quantum.Job.set_schedule(parsed_cron)
    |> Quantum.Job.set_task(fn ->
      # Emit job executed metrics
      :telemetry.execute(
        [:croniq, :scheduler, :jobs, :executed],
        %{count: 1},
        %{task_type: "recurring"}
      )

      :telemetry.execute(
        [:croniq, :tasks, :recurring, :executed],
        %{count: 1},
        %{}
      )

      Croniq.Requests.send_request(task.id)
    end)
    |> Croniq.Scheduler.add_job()

    Croniq.Scheduler.activate_job(job_name)

    # Emit job count update
    update_job_count_metrics()
  end

  def update_quantum_job(task_id, task_schedule) do
    parsed_cron = Crontab.CronExpression.Parser.parse!(task_schedule)
    job_name = String.to_atom("request_by_task_#{task_id}")

    Croniq.Scheduler.find_job(job_name)
    |> Quantum.Job.set_schedule(parsed_cron)
    |> Croniq.Scheduler.add_job()
  end

  def create_delayed_job(task) do
    delay_seconds = DateTime.diff(task.scheduled_at, DateTime.utc_now(), :second)

    if delay_seconds > 0 do
      Task.start(fn ->
        Process.sleep(delay_seconds * 1000)
        __MODULE__.execute_delayed_task(task.id)
      end)
    end
  end

  def execute_delayed_task(task_id) do
    case Croniq.Repo.get(Croniq.Task, task_id) do
      %Croniq.Task{task_type: "delayed", status: "active"} = task ->
        # Emit delayed task executed metric
        :telemetry.execute(
          [:croniq, :tasks, :delayed, :executed],
          %{count: 1},
          %{}
        )

        :telemetry.execute(
          [:croniq, :scheduler, :jobs, :executed],
          %{count: 1},
          %{task_type: "delayed"}
        )

        result = Croniq.Requests.send_request(task.id)

        if result == :ok do
          task
          |> Ecto.Changeset.change(%{
            status: "completed",
            executed_at: DateTime.utc_now()
          })
          |> Croniq.Repo.update()

          Logger.info("Delayed task #{task.id} executed successfully")
        else
          Logger.error("Failed to execute delayed task #{task.id}: #{inspect(result)}")
        end

      _ ->
        Logger.warning("Delayed task #{task_id} not found or already executed")
    end
  end

  defp update_job_count_metrics do
    # Get task counts from database
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
end
