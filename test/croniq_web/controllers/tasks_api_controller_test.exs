defmodule CroniqWeb.TasksAPIControllerTest do
  use CroniqWeb.ConnCase, async: true
  import Croniq.AccountsFixtures
  import Croniq.TaskFixtures

  setup %{conn: conn} do
    user = user_fixture()
    %{user: user, conn: conn, user_token: Croniq.Accounts.create_user_api_token(user)}
  end

  # TOOD: add describes
  test "Tasks list", %{conn: conn, user: user, user_token: user_token} do
    task_list_for_user(user, 20)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> get(~p"/api/v1/tasks")
      |> json_response(200)

    assert %{"results" => results} = response
    assert length(results) == 20
  end

  test "Task list contain all required keys", %{conn: conn, user: user, user_token: user_token} do
    task_list_for_user(user)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> get(~p"/api/v1/tasks")
      |> json_response(200)

    assert %{"results" => results} = response

    assert Enum.all?(
             [
               "body",
               "headers",
               "id",
               "method",
               "name",
               "retry_count",
               "schedule",
               "status",
               "url"
             ],
             &Map.has_key?(Enum.at(results, 0), &1)
           )
  end

  test "Alien task list", %{conn: conn, user_token: user_token} do
    alien = user_fixture()
    task_list_for_user(alien, 1)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> get(~p"/api/v1/tasks")
      |> json_response(200)

    assert %{"results" => results} = response
    assert Enum.empty?(results)
  end

  @tag :skip
  test "Tasks list pagination" do
    # TODO implement
    assert false
  end

  test "Task detail", %{conn: conn, user: user, user_token: user_token} do
    tasks = task_list_for_user(user)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> get(~p"/api/v1/tasks/#{Map.fetch!(Enum.at(tasks, 0), :id)}")
      |> json_response(200)

    assert Enum.all?(
             [
               "body",
               "headers",
               "id",
               "method",
               "name",
               "retry_count",
               "schedule",
               "status",
               "url"
             ],
             &Map.has_key?(response, &1)
           )
  end

  test "Task detail alien", %{conn: conn, user_token: user_token} do
    alien_task =
      user_fixture()
      |> task_list_for_user()
      |> Enum.at(0)

    conn
    |> put_req_header("authorization", "Basic " <> user_token)
    |> get(~p"/api/v1/tasks/#{Map.fetch!(alien_task, :id)}")
    |> json_response(404)
  end

  test "Task create", %{conn: conn, user: user, user_token: user_token} do
    user
    |> task_list_for_user()
    |> Enum.at(0)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> post(~p"/api/v1/tasks", %{
        "body" => "",
        "headers" => "",
        "method" => "GET",
        "name" => "cron job",
        "schedule" => "* * * * *",
        "url" => "https://example.com"
      })
      |> json_response(200)

    assert Enum.all?(
             [
               "body",
               "headers",
               "id",
               "method",
               "name",
               "retry_count",
               "schedule",
               "status",
               "url"
             ],
             &Map.has_key?(response, &1)
           )
  end

  test "Task create without fields", %{conn: conn, user: user, user_token: user_token} do
    user
    |> task_list_for_user()
    |> Enum.at(0)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> post(~p"/api/v1/tasks", %{
        "body" => "",
        "headers" => "",
        "method" => "GET",
        "schedule" => "* * * * *",
        "url" => "https://example.com"
      })
      |> json_response(422)

    assert %{"errors" => %{"name" => [txt]}} = response
    # TODO: probably more context in error message
    assert txt == "can't be blank"
  end

  test "Invalid cron", %{conn: conn, user: user, user_token: user_token} do
    user
    |> task_list_for_user()
    |> Enum.at(0)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> post(~p"/api/v1/tasks", %{
        "name" => "important task",
        "body" => "",
        "headers" => "",
        "method" => "GET",
        "schedule" => "68 * * * *",
        "url" => "https://example.com"
      })
      |> json_response(422)

    assert %{"errors" => %{"schedule" => [txt]}} = response
    assert txt == "Can't parse 68 as minute."
  end

  test "Task edit", %{conn: conn, user: user, user_token: user_token} do
    task =
      user
      |> task_list_for_user()
      |> Enum.at(0)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> put(~p"/api/v1/tasks/#{Map.fetch!(task, :id)}", %{
        "name" => "important task",
        "body" => "",
        "headers" => "",
        "method" => "GET",
        "schedule" => "* * * * *",
        "url" => "https://example.com"
      })
      |> json_response(200)

    assert Enum.all?(
             [
               "body",
               "headers",
               "id",
               "method",
               "name",
               "retry_count",
               "schedule",
               "status",
               "url"
             ],
             &Map.has_key?(response, &1)
           )
  end

  @tag :skip
  test "Task edit without \"name\" field", %{conn: conn, user: user, user_token: user_token} do
    task =
      user
      |> task_list_for_user()
      |> Enum.at(0)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> put(~p"/api/v1/tasks/#{Map.fetch!(task, :id)}", %{
        "body" => "",
        "headers" => "",
        "method" => "GET",
        "schedule" => "* * * * *",
        "url" => "https://example.com"
      })
      |> json_response(422)

    assert %{"errors" => %{"name" => [txt]}} = response
    assert txt == "can't be blank"
  end

  @tag :skip
  test "Task edit invalid cron", %{conn: conn, user: user, user_token: user_token} do
    task =
      user
      |> task_list_for_user()
      |> Enum.at(0)

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> put(~p"/api/v1/tasks/#{Map.fetch!(task, :id)}", %{
        "body" => "",
        "headers" => "",
        "method" => "GET",
        "schedule" => "112 * * * *",
        "url" => "https://example.com"
      })
      |> json_response(422)

    assert %{"errors" => %{"name" => [txt]}} = response
    assert txt == "Can't parse 68 as minute."
  end

  test "Tasks list search by name strictly", %{conn: conn, user: user, user_token: user_token} do
    Croniq.Task.create_task(user.id, %{
      "name" => "Alpha",
      "schedule" => "* * * * *",
      "url" => "https://example.com",
      "method" => "GET"
    })

    Croniq.Task.create_task(user.id, %{
      "name" => "Alp",
      "schedule" => "* * * * *",
      "url" => "https://example.com",
      "method" => "GET"
    })

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> get(~p"/api/v1/tasks?name=Alp")
      |> json_response(200)

    assert %{"results" => results} = response
    assert length(results) == 1
    [%{"name" => name}] = results
    assert name == "Alp"
  end

  test "Delayed task create via API", %{conn: conn, user_token: user_token} do
    future_time =
      DateTime.add(DateTime.utc_now(), 3600, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> post(~p"/api/v1/tasks/delayed", %{
        "name" => "Delayed API task",
        "url" => "https://example.com",
        "method" => "POST",
        "headers" => %{},
        "body" => "",
        "scheduled_at" => future_time
      })
      |> json_response(200)

    assert response["task_type"] == "delayed"
    assert response["scheduled_at"] == future_time
    assert response["status"] == "active"
  end

  test "Delayed task create via API fails with past scheduled_at", %{
    conn: conn,
    user_token: user_token
  } do
    past_time =
      DateTime.add(DateTime.utc_now(), -3600, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> post(~p"/api/v1/tasks/delayed", %{
        "name" => "Delayed API task",
        "url" => "https://example.com",
        "method" => "POST",
        "headers" => %{},
        "body" => "",
        "scheduled_at" => past_time
      })
      |> json_response(422)

    assert %{"errors" => %{"scheduled_at" => [msg]}} = response
    assert msg == "must be in the future"
  end

  test "Delayed task edit via API", %{conn: conn, user: user, user_token: user_token} do
    future_time =
      DateTime.add(DateTime.utc_now(), 3600, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    {:ok, task} =
      Croniq.Task.create_delayed_task(user.id, %{
        "name" => "Delayed API task",
        "url" => "https://example.com",
        "method" => "POST",
        "headers" => %{},
        "body" => "",
        "scheduled_at" => future_time,
        "task_type" => "delayed"
      })

    new_time =
      DateTime.add(DateTime.utc_now(), 7200, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()

    response =
      conn
      |> put_req_header("authorization", "Basic " <> user_token)
      |> put(~p"/api/v1/tasks/delayed/#{task.id}", %{
        "name" => "Updated delayed task",
        "scheduled_at" => new_time,
        "task_type" => "delayed"
      })
      |> json_response(200)

    assert response["name"] == "Updated delayed task"
    assert response["scheduled_at"] == new_time
    assert response["task_type"] == "delayed"
  end
end
