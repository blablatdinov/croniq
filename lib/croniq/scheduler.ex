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

  def create_quantum_job(task) do
    parsed_cron = Crontab.CronExpression.Parser.parse!(task.schedule)
    job_name = String.to_atom("request_by_task_#{task.schedule}")

    Croniq.Scheduler.new_job()
    |> Quantum.Job.set_name(job_name)
    |> Quantum.Job.set_schedule(parsed_cron)
    |> Quantum.Job.set_task(fn -> Croniq.Requests.send_request(task.id) end)
    |> Croniq.Scheduler.add_job()

    Croniq.Scheduler.activate_job(job_name)
  end

  def update_quantum_job(task) do
    parsed_cron = Crontab.CronExpression.Parser.parse!(task.schedule)
    job_name = String.to_atom("request_by_task_#{task.schedule}")

    Croniq.Scheduler.find_job(job_name)
    |> Quantum.Job.set_schedule(parsed_cron)
  end
end
