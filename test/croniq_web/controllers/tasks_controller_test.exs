defmodule CroniqWeb.TasksControllerTest do
  use CroniqWeb.ConnCase, async: true
  import Croniq.AccountsFixtures
  import Croniq.TaskFixtures

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, CroniqWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    user = user_fixture()

    %{user: user, conn: conn, user_token: Croniq.Accounts.generate_user_session_token(user)}
  end

  describe "Test request logs" do
    test "Read record log list", %{conn: conn, user_token: user_token, user: user} do
      [task] = task_list_for_user(user)
      requests_log(task, 15)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/#{task.id}/requests-log")
        |> html_response(200)

      parsed = Floki.parse_document!(response)
      assert length(Floki.find(parsed, "[data-test=rq-log-line]")) == 15
    end

    test "Read log detail", %{conn: conn, user_token: user_token, user: user} do
      [task] = task_list_for_user(user)
      [rq_log] = requests_log(task, 1)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/#{task.id}/requests-log/#{rq_log.id}")
        |> html_response(200)

      [{"span", _attrs, [text]}] =
        Floki.find(Floki.parse_document!(response), "[data-test=rq-log-id]")

      assert text =~ "Log ID: #{rq_log.id}"
    end

    test "Alien request log list", %{conn: conn, user_token: user_token} do
      alien_user = user_fixture()
      [task] = task_list_for_user(alien_user)
      requests_log(task, 5)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/#{task.id}/requests-log")
        |> html_response(200)

      assert

      response
      |> Floki.parse_document!()
      |> Floki.find("[data-test=rq-log-line]")
      |> Enum.empty?()
    end

    test "Alien request log detail", %{conn: conn, user_token: user_token} do
      alien_user = user_fixture()
      [task] = task_list_for_user(alien_user)
      [rq_log] = requests_log(task)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/#{task.id}/requests-log/#{rq_log.id}")
        |> html_response(404)

      assert

      response
      |> Floki.parse_document!()
      |> Floki.find("[data-test=rq-log-line]")
      |> Enum.empty?()
    end
  end
end
