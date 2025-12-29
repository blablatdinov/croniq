# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.APIAuthControllerTest do
  use CroniqWeb.ConnCase
  import Croniq.AccountsFixtures

  test "POST /api/v1/auth", %{conn: conn} do
    user_fixture(%{email: "a.ilaletdinov@yandex.ru", password: "longStrongPassword"})

    response =
      conn
      |> post(~p"/api/v1/auth", %{
        "email" => "a.ilaletdinov@yandex.ru",
        "password" => "longStrongPassword"
      })
      |> json_response(200)

    assert %{"token" => token} = response
    assert token
  end

  test "Invalid auth data", %{conn: conn} do
    user_fixture(%{email: "a.ilaletdinov@yandex.ru", password: "longStrongPassword"})

    response =
      conn
      |> post(~p"/api/v1/auth", %{
        "email" => "a.ilaletdinov@yandex.ru",
        "password" => "incorrectPassword"
      })
      |> json_response(401)

    assert %{"error" => error} = response
    assert error == "Invalid email or password"
  end

  @tag :skip
  test "Remove token" do
    # TODO: implement
    assert false
  end
end
