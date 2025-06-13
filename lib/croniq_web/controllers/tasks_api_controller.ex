defmodule CroniqWeb.TasksAPIController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task
  import Croniq.Requests
  import Ecto.Query
  import Crontab.CronExpression
  import Logger

  def list(conn, _params) do
    tasks =
      Repo.all(from task in Task, where: task.user_id == ^conn.assigns.current_user.id)
      |> Enum.map(fn task ->
        Map.from_struct(task)
        |> Map.drop([:user, :__meta__])
      end)

    render(conn, :list, tasks: tasks)
  end

  def detail(conn, %{"task_id" => task_id}) do
    task =
      Repo.get_by!(Task, id: task_id)
      |> Map.from_struct()
      |> Map.drop([:user, :__meta__])
    render(conn, :detail, task: task)
  end
end
