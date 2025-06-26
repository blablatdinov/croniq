defmodule CroniqWeb.AccountsControllerTest do
  use CroniqWeb.ConnCase, async: true
  import Croniq.AccountsFixtures
  import Croniq.TaskFixtures
  import Ecto.Query

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, CroniqWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    user = user_fixture()

    %{user: user, conn: conn, user_token: Croniq.Accounts.generate_user_session_token(user)}
  end

  test "registration form", %{conn: conn} do
    response =
      conn
      |> get(~p"/users/register")
      |> html_response(200)
  end

  test "registration", %{conn: conn} do
    response =
      conn
      |> post(~p"/users/register")
      |> html_response(302)
  end
end
