defmodule Croniq.TaskTest do
  use Croniq.DataCase, async: true
  import Croniq.AccountsFixtures
  alias Croniq.Task

  test "update_task updates fields and updates Quantum.Job" do
    user = user_fixture()

    {:ok, task} =
      Task.create_task(user.id, %{
        "name" => "Test task",
        "schedule" => "* * * * *",
        "url" => "https://example.com",
        "method" => "GET"
      })

    job_name = String.to_atom("request_by_task_#{task.id}")
    Croniq.Scheduler.create_quantum_job(task)
    new_schedule = "*/5 * * * *"

    attrs = %{
      "name" => "Updated name",
      "url" => "https://updated.com",
      "schedule" => new_schedule
    }

    {:ok, _} = Task.update_task(task, attrs)
    job = Croniq.Scheduler.find_job(job_name)
    assert job.schedule == Crontab.CronExpression.Parser.parse!(new_schedule)
  end
end
