defmodule Croniq.Repo.Migrations.AddDelayedTaskFields do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :task_type, :string, default: "recurring", null: false
      add :scheduled_at, :utc_datetime
      add :executed_at, :utc_datetime
    end

    create index(:tasks, [:task_type])
    create index(:tasks, [:scheduled_at])
  end
end
