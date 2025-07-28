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

defmodule CroniqWeb.AccountsControllerTest do
  use CroniqWeb.ConnCase, async: true
  import Croniq.AccountsFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, CroniqWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    user = user_fixture()

    %{user: user, conn: conn, user_token: Croniq.Accounts.generate_user_session_token(user)}
  end

  test "registration form", %{conn: conn} do
    Application.put_env(:croniq, :registration_enabled, true)

    _response =
      conn
      |> get(~p"/users/register")
      |> html_response(200)
  end

  test "registration", %{conn: conn} do
    Application.put_env(:croniq, :registration_enabled, true)

    user_params = %{
      "email" => "test@example.com",
      "password" => "valid_password",
      "password_confirmation" => "valid_password"
    }

    conn =
      conn
      |> post(~p"/users/register", %{"user" => user_params, "recaptcha_token" => "test_token"})

    # Should redirect to new task page after successful registration
    assert redirected_to(conn) == ~p"/tasks/new"
  end

  test "reset_password_form with invalid token redirects with error", %{conn: conn} do
    conn = get(conn, ~p"/users/reset_password/invalidtoken")
    assert redirected_to(conn) == ~p"/"

    assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
             "Reset password link is invalid or it has expired."
  end
end
