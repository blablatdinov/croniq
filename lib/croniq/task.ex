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
  alias Croniq.Repo
  import Ecto.Changeset
  require Logger

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
      :user_id
    ])
    |> validate_required([:name, :schedule, :url])
    |> put_default(:body, "")
    |> put_default(:status, "active")
    |> put_default(:retry_count, 0)
    |> validate_change(:schedule, fn :schedule, schedule ->
      case Crontab.CronExpression.Parser.parse(schedule) do
        {:ok, _} -> []
        {:error, error} -> [schedule: error]
      end
    end)
    |> validate_inclusion(:method, ~w(GET POST PUT DELETE))
  end

  def create_changeset(task, attrs, user_id) do
    task
    |> changeset(attrs)
    |> put_default(:user_id, user_id)

    # |> put_assoc(:user, user)
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

  defp decode_json(""), do: %{}

  defp decode_json(str) when is_binary(str) do
    case Jason.decode(str) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{}
    end
  end

  defp decode_json(val), do: val

  defp put_default(changeset, field, default) do
    if Map.get(changeset.changes, field) == nil do
      put_change(changeset, field, default)
    else
      changeset
    end
  end
end
