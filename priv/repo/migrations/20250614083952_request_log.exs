defmodule Croniq.Repo.Migrations.RequestLog do
  use Ecto.Migration

  def change do
    create table(:request_log) do
      add :request, :text, null: false
      add :response, :text
      add :duration, :integer, null: false
      add :error, :integer
      add :task_id, references(:tasks)

      timestamps(type: :utc_datetime)
    end
  end
end
