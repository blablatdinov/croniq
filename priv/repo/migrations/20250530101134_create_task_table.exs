# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule :"Elixir.Croniq.Repo.Migrations.Create task table" do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :name, :string, null: false
      add :schedule, :string, null: false
      add :url, :string, null: false
      add :method, :string, null: false
      add :headers, :map, null: false
      add :body, :text, null: false
      add :status, :string, null: false
      add :retry_count, :integer, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
