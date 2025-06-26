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
    _response =
      conn
      |> get(~p"/users/register")
      |> html_response(200)
  end

  test "registration", %{conn: conn} do
    user_params = %{
      "email" => "test@example.com",
      "password" => "valid_password",
      "password_confirmation" => "valid_password"
    }

    conn =
      conn
      |> post(~p"/users/register", %{"user" => user_params, "recaptcha_token" => "test_token"})

    # Should redirect after successful registration
    assert redirected_to(conn) == ~p"/tasks/new"
  end
end
