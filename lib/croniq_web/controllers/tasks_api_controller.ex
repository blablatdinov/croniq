defmodule CroniqWeb.TasksAPIController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task
  import Ecto.Query

  action_fallback CroniqWeb.FallbackController

  def list(conn, params) do
    name = Map.get(params, "name")

    query =
      from task in Task,
        where: task.user_id == ^conn.assigns.current_user.id

    query =
      if name && name != "" do
        pattern = "%" <> name <> "%"
        from task in query, where: ilike(task.name, ^pattern)
      else
        query
      end

    tasks =
      Repo.all(query)
      |> Enum.map(fn task ->
        Map.from_struct(task)
        |> Map.drop([:user, :__meta__])
      end)

    render(conn, :list, tasks: tasks)
  end

  def detail(conn, %{"task_id" => task_id}) do
    case Repo.get_by(Task, id: task_id, user_id: conn.assigns.current_user.id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{"detail" => "Not Found"})

      task ->
        response_task =
          task
          |> Map.from_struct()
          |> Map.drop([:user, :__meta__])

        render(conn, :detail, task: response_task)
    end
  end

  def create conn, params do
    case Croniq.Task.create_task(conn.assigns.current_user.id, params) do
      {:ok, task} ->
        response_task =
          task
          |> Map.from_struct()
          |> Map.drop([:user, :__meta__])

        render(conn, :detail, task: response_task)

      another ->
        another
    end
  end

  def create_delayed(conn, params) do
    case Croniq.Task.create_delayed_task(conn.assigns.current_user.id, params) do
      {:ok, task} ->
        response_task =
          task
          |> Map.from_struct()
          |> Map.drop([:user, :__meta__])

        render(conn, :detail, task: response_task)
      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{errors: changeset.errors})
    end
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
