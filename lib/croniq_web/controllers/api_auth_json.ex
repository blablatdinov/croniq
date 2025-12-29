# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.APIAuthJSON do
  def generate_token(%{token: token}) do
    %{"token" => token}
  end
end
