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
