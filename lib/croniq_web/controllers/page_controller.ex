defmodule CroniqWeb.PageController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task

  def home(conn, _params) do
    render(conn, :home)
  end

  def tasks(conn, _params) do
    tasks = [
      %{id: 1, name: "Backup DB", schedule: "0 3 * * *", status: "active"},
      %{id: 2, name: "Clean Cache", schedule: "*/15 * * * *", status: "inactive"},
      %{id: 3, name: "Send Reports", schedule: "0 9 * * 1", status: "active"}
    ]

    render(conn, :tasks, tasks: tasks)
  end

  def new_task(conn, _params) do
    render(conn, :new_task, changeset: Task.changeset(%Task{}, %{}))
  end

  defp create_task(attrs) do
    %Task{} |> Task.changeset(attrs) |> Repo.insert()
  end

  def create(conn, %{"task" => task_params}) do
    case create_task(task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Task created successfully!")
        |> redirect(to: ~p"/tasks/#{task.id}/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        render(conn, :new_task, changeset: changeset)
    end
  end

  def edit(conn, %{"task_id" => task_id}) do
    task = %{id: task_id, name: "Backup DB", schedule: "0 3 * * *", status: "active"}
    render(conn, :edit, task: task)
  end

  def delete(conn, %{"task_id" => task_id}) do
    conn
    |> put_flash(:info, "Task deleted successfully")
    |> redirect(to: ~p"/tasks")
  end
end
