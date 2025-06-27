defmodule Croniq.Repo.Migrations.AddPlaintextTokenToUsersTokens do
  use Ecto.Migration

  def change do
    alter table(:users_tokens) do
      add :plaintext_token, :string
    end
  end
end
