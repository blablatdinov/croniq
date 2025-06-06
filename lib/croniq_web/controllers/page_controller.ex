defmodule CroniqWeb.PageController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task
  import Croniq.Requests
  import Crontab.CronExpression
  import Logger

  def home(conn, _params) do
    render(conn, :home)
  end

  def tasks(conn, _params) do
    render(conn, :tasks, tasks: Repo.all(Task))
  end

  def new_task(conn, _params) do
    render(conn, :new_task, changeset: Task.changeset(%Task{}, %{}))
  end

  defp create_task(attrs) do
    parsed_cron = Map.fetch!(attrs, "schedule") |> Crontab.CronExpression.Parser.parse!()
    task = %Task{} |> Task.changeset(attrs) |> Repo.insert!()
    job_name = String.to_atom("request_by_task_#{task.schedule}")

    Croniq.Scheduler.new_job()
    |> Quantum.Job.set_name(job_name)
    |> Quantum.Job.set_schedule(parsed_cron)
    |> Quantum.Job.set_task(fn -> send_request(task.id) end)
    |> Croniq.Scheduler.add_job()

    Croniq.Scheduler.activate_job(job_name)
    Logger.info("Quantum job for task record id=#{task.id} created from form input")
    {:ok, task}
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
