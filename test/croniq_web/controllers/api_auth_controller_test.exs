# The MIT License (MIT).
#
# Copyright (c) 2025 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

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
