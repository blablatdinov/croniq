# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.APIAuthController do
  use CroniqWeb, :controller

  def generate_token(conn, %{"email" => email, "password" => password}) do
    case Croniq.Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        conn
        |> put_status(:unauthorized)
        |> json(%{"error" => "Invalid email or password"})
        |> halt()

      user ->
        token = Croniq.Accounts.create_user_api_token(user)
        render(conn, :generate_token, token: token)
    end
  end
end
