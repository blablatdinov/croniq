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

defmodule Croniq.Task do
  @moduledoc """
  Defines the Task schema and business logic for scheduled jobs.

  Responsibilities:
  - CRUD operations for scheduled tasks
  - Cron schedule validation
  - HTTP request configuration
  - State management (active/retry status)
  - Integration with Quantum scheduler

  Tasks belong to users and contain all necessary metadata to execute HTTP requests
  on a defined schedule.
  """
  use Ecto.Schema
  import Ecto.Query

  import Ecto.Changeset
  require Logger
  alias Croniq.Repo

  schema "tasks" do
    belongs_to :user, Croniq.Accounts.User

    field :name, :string
    field :schedule, :string
    field :url, :string
    field :method, :string
    field :headers, :map
    field :body, :string
    field :status, :string
    field :retry_count, :integer
    field :task_type, :string, default: "recurring"
    field :scheduled_at, :utc_datetime
    field :executed_at, :utc_datetime

    timestamps()
  end

  def changeset(task, attrs) do
    attrs =
      Map.update(attrs, "headers", %{}, fn headers ->
        if is_binary(headers), do: decode_json(headers), else: headers
      end)

    task
    |> cast(attrs, [
      :name,
      :schedule,
      :url,
      :method,
      :headers,
      :body,
      :status,
      :retry_count,
      :user_id,
      :task_type,
      :scheduled_at,
      :task_type,
      :executed_at
    ])
    |> validate_required([:name, :url])
    |> put_default(:body, "")
    |> put_default(:status, "active")
    |> put_default(:retry_count, 0)
    |> validate_task_type()
    |> validate_schedule_for_recurring()
    |> validate_scheduled_at_for_delayed()
    |> put_default(:schedule, "")
    |> validate_inclusion(:method, ~w(GET POST PUT DELETE))
  end

  defp validate_task_type(changeset) do
    validate_inclusion(changeset, :task_type, ~w(recurring delayed))
  end

  defp validate_schedule_for_recurring(changeset) do
    if get_field(changeset, :task_type) == "recurring" do
      changeset
      |> validate_required([:schedule])
      |> validate_cron_schedule()
    else
      changeset
    end
  end

  defp validate_cron_schedule(changeset) do
    validate_change(changeset, :schedule, fn :schedule, schedule ->
      case Crontab.CronExpression.Parser.parse(schedule) do
        {:ok, _} -> []
        {:error, error} -> [schedule: error]
      end
    end)
  end

  defp validate_scheduled_at_for_delayed(changeset) do
    if get_field(changeset, :task_type) == "delayed" do
      changeset
      |> validate_required([:scheduled_at])
      |> validate_change(:scheduled_at, fn :scheduled_at, scheduled_at ->
        cond do
          is_nil(scheduled_at) -> []
          DateTime.compare(scheduled_at, DateTime.utc_now()) == :gt -> []
          true -> [scheduled_at: "must be in the future"]
        end
      end)
    else
      changeset
    end
  end

  def create_changeset(task, attrs, user_id) do
    task
    |> changeset(attrs)
    |> put_default(:user_id, user_id)
  end

  def update_task(task, attrs) do
    updated_task =
      task
      |> changeset(attrs)
      |> Repo.update()

    Croniq.Scheduler.update_quantum_job(task.id, attrs["schedule"])
    Logger.info("Quantum job for task record id=#{task.id} updated")
    updated_task
  end

  def update_delayed_task(task, attrs) do
    updated_task =
      task
      |> changeset(attrs)
      |> Repo.update()

    case updated_task do
      {:ok, updated} ->
        if Map.has_key?(attrs, "scheduled_at") and not is_nil(updated.scheduled_at) do
          Croniq.Scheduler.create_delayed_job(updated)
        end

        Logger.info("Delayed task record id=#{updated.id} updated")
        {:ok, updated}

      other ->
        other
    end
  end

  def create_task(user_id, attrs) do
    case %Croniq.Task{} |> Croniq.Task.create_changeset(attrs, user_id) do
      %{valid?: false} = changeset ->
        {:error, changeset}

      changeset ->
        task = Repo.insert!(changeset)
        job_name = String.to_atom("request_by_task_#{task.schedule}")
        Croniq.Scheduler.create_quantum_job(task)

        Croniq.Scheduler.activate_job(job_name)
        Logger.info("Quantum job for task record id=#{task.id} created from form input")
        {:ok, task}
    end
  end

  def create_delayed_task(user_id, attrs) do
    attrs = Map.put(attrs, "task_type", "delayed")

    case %Croniq.Task{} |> Croniq.Task.create_changeset(attrs, user_id) do
      %{valid?: false} = changeset ->
        {:error, changeset}

      changeset ->
        task = Repo.insert!(changeset)
        Croniq.Scheduler.create_delayed_job(task)
        Logger.info("Delayed task created with id=#{task.id}, scheduled for #{task.scheduled_at}")
        {:ok, task}
    end
  end

  def delete_with_logs(task) do
    Repo.transaction(fn ->
      Croniq.RequestLog
      |> where(task_id: ^task.id)
      |> Repo.delete_all()

      Repo.delete!(task)
    end)
  end

  defp decode_json(""), do: %{}

  defp decode_json(str) when is_binary(str) do
    case Jason.decode(str) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{}
    end
  end

  defp decode_json(val), do: val

  defp put_default(changeset, field, default) do
    if Map.get(changeset.changes, field) == nil and get_field(changeset, field) in [nil, ""] do
      put_change(changeset, field, default)
    else
      changeset
    end
  end
end
