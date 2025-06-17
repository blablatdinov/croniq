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
      {:ok, request_log} = Croniq.RequestLog.create_rq_log(%{
          "task_id" => task.id,
          "request" => "string",
          "response" => "string",
          "duration" => 430,
          "error" => "",
        })
      request_log
    end)
  end
end
