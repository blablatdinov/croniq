# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule Croniq.Repo do
  use Ecto.Repo,
    otp_app: :croniq,
    adapter: Ecto.Adapters.Postgres
end
