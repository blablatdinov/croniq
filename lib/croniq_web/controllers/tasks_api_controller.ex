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
      Repo.get_by!(Task, id: task_id, user_id: conn.assigns.current_user.id)
      |> Map.from_struct()
      |> Map.drop([:user, :__meta__])

    render(conn, :detail, task: task)
  end

  def create(conn, params) do
    {:ok, task} = Croniq.Task.create_task(conn.assigns.current_user.id, params)

    response_task =
      task
      |> Map.from_struct()
      |> Map.drop([:user, :__meta__])

    render(conn, :detail, task: response_task)
  end

  def edit(conn, params) do
    task = Repo.get_by!(Task, id: params["task_id"], user_id: conn.assigns.current_user.id)
    {:ok, task} = Task.update_task(task, params)

    response_task =
      task
      |> Map.from_struct()
      |> Map.drop([:user, :__meta__])

    render(conn, :detail, task: response_task)
  end

  def delete(conn, %{"task_id" => task_id}) do
    case Repo.get_by(Task, id: task_id, user_id: conn.assigns.current_user.id) do
      {:ok, task} -> Repo.delete!(task)
      _ -> nil
    end

    put_status(conn, :no_content) |> json(nil)
  end
end
