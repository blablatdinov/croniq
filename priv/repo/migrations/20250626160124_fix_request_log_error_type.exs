# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule Croniq.Repo.Migrations.FixRequestLogErrorType do
  use Ecto.Migration

  def change do
    alter table(:request_log) do
      modify :error, :text
    end
  end
end
