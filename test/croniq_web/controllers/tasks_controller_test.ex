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
  end
end
