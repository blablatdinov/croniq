defmodule CroniqWeb.TasksController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task
  import Croniq.Requests
  import Crontab.CronExpression
  import Logger

  def create(conn, %{"task" => task_params}) do
    case Croniq.Task.create_task(conn.assigns.current_user.id, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task created successfully!")
        |> redirect(to: ~p"/tasks/#{task.id}/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        render(conn, :new_task, changeset: changeset)
    end
  end

  def tasks(conn, _params) do
    render(conn, :tasks, tasks: Repo.all(Task))
  end

  def new_task(conn, _params) do
    render(conn, :new_task, changeset: Task.changeset(%Task{}, %{}))
  end

  def create(conn, %{"task" => task_params}) do
    case Croniq.Task.create_task(conn, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task created successfully!")
        |> redirect(to: ~p"/tasks/#{task.id}/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        render(conn, :new_task, changeset: changeset)
    end
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
      {:ok, task} ->
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
end
