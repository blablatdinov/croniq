defmodule CroniqWeb.TasksController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task
  require Logger
  import Ecto.Query

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
    render(conn, :tasks, tasks: Repo.all(Task))
  end

  def new_task(conn, _params) do
    render(conn, :new_task, changeset: Task.changeset(%Task{}, %{}))
  end

  def task_details(conn, %{"task_id" => task_id}) do
    redirect(conn, to: ~p"/tasks/#{task_id}/edit")
  end

  def edit_form(conn, %{"task_id" => task_id}) do
    task = Repo.get_by!(Task, id: task_id)
    render(conn, :edit, task: task, changeset: Task.changeset(task, %{}))
  end

  def edit(conn, %{"task_id" => task_id, "task" => task_params}) do
    task = Repo.get_by!(Task, id: task_id)

    case Task.update_task(task, task_params) do
      {:ok, _task} ->
        conn
        |> put_flash(:info, "Task updated successfully.")
        |> redirect(to: ~p"/tasks/#{task_id}/edit")
    end

    render(conn, :edit, task: task)
  end

  def delete(conn, %{"task_id" => task_id}) do
    Repo.get_by!(Task, id: task_id)
    |> Repo.delete!()

    conn
    |> put_flash(:info, "Task deleted successfully")
    |> redirect(to: ~p"/tasks")
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
      Repo.one!(
        from rq_log in Croniq.RequestLog,
          join: task in Croniq.Task,
          on: rq_log.task_id == task.id,
          where:
            task.user_id == ^conn.assigns.current_user.id and
              rq_log.id == ^rq_log_id,
          order_by: [desc: rq_log.id]
      )

    render(conn, :request_log_detail, rq_log: rq_log)
  end
end
