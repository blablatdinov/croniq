defmodule Croniq.Repo.Migrations.FixRequestLogErrorType do
  use Ecto.Migration

  def change do
    alter table(:request_log) do
      modify :error, :text
    end
  end
end
