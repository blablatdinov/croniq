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
    assert html_response(conn, 200) =~ key.plaintext_token
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

  test "GET /api/v1/tasks with valid API key from API endpoint returns tasks", %{user: user} do
    # Создаём таску для пользователя
    {:ok, _task} =
      Croniq.Task.create_task(user.id, %{
        "name" => "Test",
        "schedule" => "* * * * *",
        "url" => "https://example.com",
        "method" => "GET"
      })

    # Получаем токен через API
    conn =
      build_conn()
      |> put_req_header("content-type", "application/json")
      |> post("/api/v1/auth", %{email: user.email, password: "hello world!"} |> Jason.encode!())

    token = Jason.decode!(conn.resp_body)["token"]

    # Делаем запрос с этим токеном
    conn =
      build_conn()
      |> put_req_header("authorization", "Basic #{token}")
      |> get("/api/v1/tasks")

    assert json_response(conn, 200)["results"] |> is_list()
    assert Enum.any?(json_response(conn, 200)["results"], fn t -> t["name"] == "Test" end)
  end

  test "GET /api/v1/tasks with invalid API key returns 401" do
    conn =
      build_conn()
      |> put_req_header("authorization", "Basic invalidtoken")
      |> get("/api/v1/tasks")

    assert response(conn, 401) =~ "No access for you"
  end

  test "GET /api/v1/tasks with API key created via UI returns tasks", %{conn: conn, user: user} do
    # Создаём таску для пользователя
    {:ok, _task} =
      Croniq.Task.create_task(user.id, %{
        "name" => "Test",
        "schedule" => "* * * * *",
        "url" => "https://example.com",
        "method" => "GET"
      })

    # Получаем токен через UI (POST /api_keys)
    conn =
      conn
      |> log_in_user(user)
      |> post(~p"/api_keys")
      |> get(~p"/api_keys")

    # Парсим токен из HTML (берём первый токен из таблицы)
    token_base64 =
      conn.resp_body
      |> Floki.parse_document!()
      |> Floki.find("[data-test=\"api-key-token\"]")
      |> Floki.text()
      |> String.split("\n", trim: true)
      |> List.first()

    # Делаем запрос с этим токеном
    api_conn =
      build_conn()
      |> put_req_header("authorization", "Basic #{token_base64}")
      |> get("/api/v1/tasks")

    assert json_response(api_conn, 200)["results"] |> is_list()
    assert Enum.any?(json_response(api_conn, 200)["results"], fn t -> t["name"] == "Test" end)
  end
end
