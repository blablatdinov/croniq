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

defmodule Croniq.TaskFixtures do
  @moduledoc """
  Factory for generating test data.

  Helpers for:
  - Creating task lists with varied configurations
  - Setting up user-associated test scenarios

  Designed for use in both unit and integration tests.
  """
  def task_list_for_user(user, count \\ 1) do
    1..count
    |> Enum.map(fn idx ->
      {:ok, task} =
        Croniq.Task.create_task(user.id, %{
          "name" => "#{idx} task",
          "schedule" => "* * * * *",
          "url" => "https://example.com",
          "method" => "GET"
        })

      task
    end)
  end

  def requests_log(task, count \\ 1) do
    1..count
    |> Enum.map(fn _ ->
      {:ok, request_log} =
        Croniq.RequestLog.create_rq_log(%{
          "task_id" => task.id,
          "request" => "string",
          "response" => "string",
          "duration" => 430,
          "error" => ""
        })

      request_log
    end)
  end
end
