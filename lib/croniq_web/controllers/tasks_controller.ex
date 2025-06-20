defmodule CroniqWeb.TasksController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task
  require Logger
  import Ecto.Query
  import Plug.Conn
  import Phoenix.Controller

  def create conn, %{"task" => task_params} do
    case Croniq.Task.create_task(conn.assigns.current_user.id, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task created successfully!")
        |> redirect(to: ~p"/tasks/#{task.id}/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new_task, changeset: changeset)
    end
  end

  def tasks(conn, _params) do
    render(conn, :tasks,
      tasks:
        Repo.all(
          from task in Croniq.Task,
            where: task.user_id == ^conn.assigns.current_user.id
        )
    )
  end

  def new_task(conn, _params) do
    render(conn, :new_task, changeset: Task.changeset(%Task{}, %{}))
  end

  def task_details(conn, %{"task_id" => task_id}) do
    redirect(conn, to: ~p"/tasks/#{task_id}/edit")
  end

  def edit_form(conn, %{"task_id" => task_id}) do
    case user_task(task_id, conn.assigns.current_user.id) do
      task = %Croniq.Task{} ->
        render(conn, :edit, task: task, changeset: Task.changeset(task, %{}))

      _ ->
        conn
        |> put_status(:not_found)
        |> put_view(CroniqWeb.ErrorHTML)
        |> render("404.html", %{})
    end
  end

  defp user_task(task_id, user_id) do
    Repo.one(
      from task in Croniq.Task,
        where: task.id == ^task_id and task.user_id == ^user_id
    )
  end

  def edit(conn, %{"task_id" => task_id, "task" => task_params}) do
    case user_task(task_id, conn.assigns.current_user.id) do
      task = %Croniq.Task{} ->
        case Task.update_task(task, task_params) do
          {:ok, _task} ->
            conn
            |> put_flash(:info, "Task updated successfully.")
            |> redirect(to: ~p"/tasks/#{task_id}/edit")

          {:error, changeset} ->
            render(conn, :edit, task: task, changeset: changeset)
        end

      _ ->
        conn
        |> put_status(:not_found)
        |> put_view(CroniqWeb.ErrorHTML)
        |> render("404.html", %{})
    end
  end

  def delete(conn, %{"task_id" => task_id}) do
    user_id = conn.assigns.current_user.id

    case Croniq.Repo.get_by(Task, id: task_id) do
      task = %Croniq.Task{} ->
        case task.user_id do
          ^user_id ->
            Croniq.Repo.delete!(task)

            conn
            |> put_flash(:info, "Task deleted successfully")
            |> redirect(to: ~p"/tasks")

          _ ->
            conn
            |> put_status(:not_found)
            |> put_view(CroniqWeb.ErrorHTML)
            |> render("404.html", %{})
        end

      nil ->
        conn
        |> put_flash(:info, "Task deleted successfully")
        |> redirect(to: ~p"/tasks")
    end
  end

  def requests_log(conn, %{"task_id" => task_id}) do
    rq_logs =
      Repo.all(
        from rq_log in Croniq.RequestLog,
          join: task in Croniq.Task,
          on: rq_log.task_id == task.id,
          where: rq_log.task_id == ^task_id and task.user_id == ^conn.assigns.current_user.id,
          order_by: [desc: rq_log.id]
      )

    render(conn, :requests_logs, rq_logs: rq_logs)
  end

  def request_log_detail(conn, %{"rq_log_id" => rq_log_id}) do
    rq_log =
      Repo.one(
        from rq_log in Croniq.RequestLog,
          join: task in Croniq.Task,
          on: rq_log.task_id == task.id,
          where:
            task.user_id == ^conn.assigns.current_user.id and
              rq_log.id == ^rq_log_id,
          order_by: [desc: rq_log.id]
      )

    case rq_log do
      nil ->
        conn
        |> put_status(:not_found)
        |> put_view(CroniqWeb.ErrorHTML)
        |> render("404.html", %{})

      rq_log ->
        render(conn, :request_log_detail, rq_log: rq_log)
    end
  end
end
