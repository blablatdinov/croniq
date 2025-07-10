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

  test "create_delayed_task creates a valid delayed task" do
    user = user_fixture()
    future_time = DateTime.add(DateTime.utc_now(), 3600, :second) |> DateTime.truncate(:second)

    {:ok, task} =
      Task.create_delayed_task(user.id, %{
        "name" => "Delayed task",
        "url" => "https://example.com",
        "method" => "POST",
        "headers" => %{},
        "body" => "",
        "scheduled_at" => future_time
      })

    assert task.task_type == "delayed"
    assert task.scheduled_at == future_time
    assert task.status == "active"
    assert is_nil(task.executed_at)
  end

  test "create_delayed_task fails with past scheduled_at" do
    user = user_fixture()
    past_time = DateTime.add(DateTime.utc_now(), -3600, :second) |> DateTime.truncate(:second)

    {:error, changeset} =
      Task.create_delayed_task(user.id, %{
        "name" => "Delayed task",
        "url" => "https://example.com",
        "method" => "POST",
        "headers" => %{},
        "body" => "",
        "scheduled_at" => past_time
      })

    assert %{scheduled_at: ["must be in the future"]} = errors_on(changeset)
  end
end
