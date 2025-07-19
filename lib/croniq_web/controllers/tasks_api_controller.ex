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
        from task in query, where: ilike(task.name, ^name)
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

  def create(conn, params) do
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

      another ->
        another
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

  def edit_delayed(conn, %{"task_id" => task_id} = params) do
    user_id = conn.assigns.current_user.id
    task = Croniq.Repo.get_by!(Task, id: task_id, user_id: user_id, task_type: "delayed")

    case Task.update_delayed_task(task, params) do
      {:ok, task} ->
        response_task =
          task
          |> Map.from_struct()
          |> Map.drop([:user, :__meta__])

        json(conn, response_task)

      another ->
        another
    end
  end

  def delete(conn, %{"task_id" => task_id}) do
    case Repo.get_by(Task, id: task_id, user_id: conn.assigns.current_user.id) do
      {:ok, task} -> Repo.delete!(task)
      _ -> nil
    end

    put_status(conn, :no_content) |> json(nil)
  end
end
