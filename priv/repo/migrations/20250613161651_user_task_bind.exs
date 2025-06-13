defmodule :"Elixir.Croniq.Repo.Migrations.User task bind" do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :user_id, references(:users)
    end

    create index(:tasks, [:user_id])
  end
end
