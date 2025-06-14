defmodule Croniq.TaskFixtures do
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
end
