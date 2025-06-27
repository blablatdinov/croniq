defmodule CroniqWeb.ApiKeyControllerTest do
  use CroniqWeb.ConnCase, async: true

  import Croniq.AccountsFixtures
  import Ecto.Query
  alias Croniq.Accounts.UserToken
  alias Croniq.Repo

  setup %{conn: conn} do
    user = user_fixture()
    conn = log_in_user(conn, user)
    {:ok, conn: conn, user: user}
  end

  test "GET /api_keys shows user's API keys", %{conn: conn, user: user} do
    # Создаём ключ вручную
    _token = Croniq.Accounts.create_user_api_token(user)
    conn = get(conn, ~p"/api_keys")
    assert html_response(conn, 200) =~ "Your API keys"
    key = Repo.one(from t in UserToken, where: t.user_id == ^user.id and t.context == "api-token")
    assert html_response(conn, 200) =~ Base.encode64(key.token, padding: false)
  end

  test "POST /api_keys creates a new API key", %{conn: conn, user: user} do
    conn = post(conn, ~p"/api_keys")
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "API key created successfully."
    assert redirected_to(conn) == "/api_keys"
    # Проверяем, что ключ появился
    api_keys =
      Repo.all(from t in UserToken, where: t.user_id == ^user.id and t.context == "api-token")

    assert length(api_keys) == 1
  end

  test "DELETE /api_keys/:id deletes the API key", %{conn: conn, user: user} do
    _token = Croniq.Accounts.create_user_api_token(user)
    key = Repo.one(from t in UserToken, where: t.user_id == ^user.id and t.context == "api-token")
    conn = delete(conn, ~p"/api_keys/#{key.id}")
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "API key deleted."
    assert redirected_to(conn) == "/api_keys"
    refute Repo.get(UserToken, key.id)
  end

  test "DELETE /api_keys/:id with wrong id shows error", %{conn: conn} do
    conn = delete(conn, ~p"/api_keys/-1")
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Key not found."
    assert redirected_to(conn) == "/api_keys"
  end
end
