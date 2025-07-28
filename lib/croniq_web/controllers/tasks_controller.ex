# The MIT License (MIT).
#
# Copyright (c) 2025 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

defmodule CroniqWeb.TasksController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task
  require Logger
  import Ecto.Query
  import Plug.Conn
  import Phoenix.Controller

  def create(conn, %{"task" => task_params}) do
    if conn.assigns.current_user.confirmed_at do
      case get_task_type(task_params) do
        "delayed" ->
          create_delayed_task(conn, task_params)

        _ ->
          create_recurring_task(conn, task_params)
      end
    else
      conn
      |> put_flash(:error, "Please confirm your email address before creating tasks.")
      |> redirect(to: ~p"/tasks")
    end
  end

  defp get_task_type(%{"task_type" => task_type}), do: task_type
  defp get_task_type(%{"scheduled_at" => _}), do: "delayed"
  defp get_task_type(_), do: "recurring"

  defp create_delayed_task(conn, task_params) do
    case Croniq.Task.create_delayed_task(conn.assigns.current_user.id, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(
          :info,
          "Delayed task created successfully! Will execute at #{format_datetime(task.scheduled_at)}"
        )
        |> redirect(to: ~p"/tasks/#{task.id}/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new_task, changeset: changeset)
    end
  end

  defp create_recurring_task(conn, task_params) do
    case Croniq.Task.create_task(conn.assigns.current_user.id, task_params) do
      {:ok, task} ->
        conn
        |> put_flash(:info, "Recurring task created successfully!")
        |> redirect(to: ~p"/tasks/#{task.id}/edit")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new_task, changeset: changeset)
    end
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
  end

  def tasks(conn, params) do
    user_id = conn.assigns.current_user.id
    base_query = from task in Croniq.Task, where: task.user_id == ^user_id, order_by: [asc: :id]

    {_, page_size} = CroniqWeb.Pagination.parse_params(params)
    total_tasks = CroniqWeb.Pagination.total(base_query)
    total_pages = CroniqWeb.Pagination.total_pages(total_tasks, page_size)
    {page, page_size} = CroniqWeb.Pagination.parse_params(params, total_pages)
    offset = CroniqWeb.Pagination.offset(page, page_size)

    tasks =
      base_query
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    render(
      conn,
      :tasks,
      tasks: tasks,
      current_user: conn.assigns.current_user,
      page: page,
      page_size: page_size,
      total_pages: total_pages,
      total_tasks: total_tasks
    )
  end

  def new_task(conn, _params) do
    if conn.assigns.current_user.confirmed_at do
      headers_string = Jason.encode!(%{})
      changeset = Task.changeset(%Task{}, %{"headers" => headers_string})
      render(conn, :new_task, changeset: changeset)
    else
      conn
      |> put_flash(:error, "Please confirm your email address before creating tasks.")
      |> redirect(to: ~p"/tasks")
    end
  end

  def task_details(conn, %{"task_id" => task_id}) do
    redirect(conn, to: ~p"/tasks/#{task_id}/edit")
  end

  def edit_form(conn, %{"task_id" => task_id}) do
    case user_task(task_id, conn.assigns.current_user.id) do
      task = %Croniq.Task{} ->
        changeset =
          Task.changeset(task, %{"headers" => task.headers, "schedule" => task.schedule})

        render(conn, :edit, task: task, changeset: changeset)

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
    if conn.assigns.current_user.confirmed_at do
      with %Croniq.Task{} = task <- user_task(task_id, conn.assigns.current_user.id),
           {:ok, _task} <- Task.update_task(task, task_params) do
        conn
        |> put_flash(:info, "Task updated successfully.")
        |> redirect(to: ~p"/tasks/#{task_id}/edit")
      else
        nil ->
          conn
          |> put_status(:not_found)
          |> put_view(CroniqWeb.ErrorHTML)
          |> render("404.html", %{})

        {:error, changeset} ->
          task = user_task(task_id, conn.assigns.current_user.id)

          changeset =
            if is_map(Ecto.Changeset.get_field(changeset, :headers)) do
              Ecto.Changeset.put_change(
                changeset,
                :headers,
                Jason.encode!(Ecto.Changeset.get_field(changeset, :headers))
              )
            else
              changeset
            end

          render(conn, :edit, task: task, changeset: changeset)
      end
    else
      conn
      |> put_flash(:error, "Please confirm your email address before editing tasks.")
      |> redirect(to: ~p"/tasks")
    end
  end

  def delete(conn, %{"task_id" => task_id}) do
    user_id = conn.assigns.current_user.id

    case Croniq.Repo.get_by(Task, id: task_id) do
      task = %Croniq.Task{} ->
        case task.user_id do
          ^user_id ->
            Croniq.Task.delete_with_logs(task)

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

  def requests_log(conn, %{"task_id" => task_id} = params) do
    {_, page_size} = CroniqWeb.Pagination.parse_params(params)
    user_id = conn.assigns.current_user.id

    base_query =
      from rq_log in Croniq.RequestLog,
        join: task in Croniq.Task,
        on: rq_log.task_id == task.id,
        where: rq_log.task_id == ^task_id and task.user_id == ^user_id,
        order_by: [desc: rq_log.id]

    total_logs = CroniqWeb.Pagination.total(base_query)
    total_pages = CroniqWeb.Pagination.total_pages(total_logs, page_size)
    {page, page_size} = CroniqWeb.Pagination.parse_params(params, total_pages)
    offset = CroniqWeb.Pagination.offset(page, page_size)

    rq_logs =
      base_query
      |> limit(^page_size)
      |> offset(^offset)
      |> Repo.all()

    render(
      conn,
      :requests_logs,
      rq_logs: rq_logs,
      task_id: task_id,
      page: page,
      page_size: page_size,
      total_pages: total_pages,
      total_logs: total_logs
    )
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
