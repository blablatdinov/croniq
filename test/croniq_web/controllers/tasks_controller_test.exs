defmodule CroniqWeb.TasksControllerTest do
  use CroniqWeb.ConnCase, async: true
  import Croniq.AccountsFixtures
  import Croniq.TaskFixtures
  import Ecto.Query

  setup %{conn: conn} do
    conn =
      conn
      |> Map.replace!(:secret_key_base, CroniqWeb.Endpoint.config(:secret_key_base))
      |> init_test_session(%{})

    user = confirmed_user_fixture()

    %{user: user, conn: conn, user_token: Croniq.Accounts.generate_user_session_token(user)}
  end

  describe "task pages" do
    test "Read task list", %{conn: conn, user_token: user_token, user: user} do
      tasks = task_list_for_user(user, 24)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/")
        |> html_response(200)

      parsed = Floki.parse_document!(response)

      {"td", [{"class", _}, {"data-test", _}],
       [
         {"a", [{"href", url}, _, _], _}
       ]} =
        Floki.find(parsed, "[data-test=id-cell]")
        |> Enum.at(0)

      assert length(Floki.find(parsed, "[data-test=task-line]")) == 24
      assert url == "/tasks/#{Enum.at(tasks, 0).id}/edit"
    end

    test "Task detail", %{conn: conn, user: user, user_token: user_token} do
      [task] = task_list_for_user(user)

      conn
      |> put_session(:user_token, user_token)
      |> get(~p"/tasks/#{task.id}")
      |> html_response(302)
    end

    test "alien tasks not in list", %{conn: conn, user_token: user_token, user: user} do
      alien_user = user_fixture()
      task_list_for_user(alien_user, 12)
      task_list_for_user(user, 6)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/")
        |> html_response(200)

      parsed = Floki.parse_document!(response)

      assert length(Floki.find(parsed, "[data-test=task-line]")) == 6
    end

    test "Alien task detail", %{conn: conn, user_token: user_token} do
      alien_user = user_fixture()
      [alien_task] = task_list_for_user(alien_user)

      conn
      |> put_session(:user_token, user_token)
      |> get(~p"/tasks/#{alien_task.id}/edit")
      |> html_response(404)
    end

    test "Task edit form", %{conn: conn, user_token: user_token, user: user} do
      [task] = task_list_for_user(user)

      conn
      |> put_session(:user_token, user_token)
      |> get(~p"/tasks/#{task.id}/edit")
      |> html_response(200)
    end

    test "edit task", %{conn: conn, user: user} do
      [task] = task_list_for_user(user)

      conn =
        conn
        |> log_in_user(user)
        |> put(~p"/tasks/#{task.id}",
          task: %{
            name: "new name",
            headers: %{"Authorization" => "newToken"},
            schedule: "*/5 * * * *"
          }
        )

      html_response(conn, 302)

      updated_form =
        conn
        |> get(~p"/tasks/#{task.id}/edit")
        |> html_response(200)

      elem =
        Floki.parse_document!(updated_form)
        |> Floki.find("[data-test=task-headers] textarea")

      [{"textarea", [_, _, _, _, {"placeholder", placeholder}], _}] = elem

      assert placeholder ==
               "{\"Authorization\":\"newToken\"}"

      assert Plug.Conn.get_resp_header(conn, "location") == [~p"/tasks/#{task.id}/edit"]

      assert %{
               name: "new name",
               headers: %{"Authorization" => "newToken"}
             } = Croniq.Repo.get_by(Croniq.Task, id: task.id) |> Map.from_struct()
    end

    test "edit alien task", %{conn: conn, user: user} do
      alien_user = user_fixture()
      [alien_task] = task_list_for_user(alien_user)

      conn
      |> log_in_user(user)
      |> put(~p"/tasks/#{alien_task.id}",
        task: %{
          name: "new name"
        }
      )
      |> html_response(404)
    end

    test "delete task", %{conn: conn, user: user} do
      [task] = task_list_for_user(user)

      conn
      |> log_in_user(user)
      |> delete(~p"/tasks/#{task.id}")
      |> html_response(302)

      refute Croniq.Repo.exists?(from t in Croniq.Task, where: t.id == ^task.id)
    end

    test "delete not exist task", %{conn: conn, user: user} do
      conn
      |> log_in_user(user)
      |> delete(~p"/tasks/4895")
      |> html_response(302)

      refute Croniq.Repo.exists?(from t in Croniq.Task, where: t.id == 4895)
    end

    test "delete alien task", %{conn: conn, user: user} do
      alien_user = user_fixture()
      [alien_task] = task_list_for_user(alien_user)

      conn
      |> log_in_user(user)
      |> delete(~p"/tasks/#{alien_task.id}")
      |> html_response(404)

      assert Croniq.Repo.exists?(from t in Croniq.Task, where: t.id == ^alien_task.id)
    end

    test "Task create form", %{conn: conn, user_token: user_token} do
      html =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/new")
        |> html_response(200)

      request_body_input =
        Floki.parse_document!(html)
        |> Floki.find("[data-test=request-body-input]")

      [
        {"textarea",
         [
           {"id", id},
           {"name", name} | _
         ], _}
      ] = request_body_input

      assert id == "task_request_body"
      assert name == "task[request_body]"
    end

    test "Not authorized", %{conn: conn} do
      Enum.reduce(
        CroniqWeb.Router.__routes__(),
        [],
        fn route, acc ->
          if route.helper in ["tasks"] do
            acc ++ [String.replace(route.path, ":task_id", "1")]
          else
            acc
          end
        end
      )
      |> Enum.each(fn route ->
        response = get(conn, route)
        assert Plug.Conn.get_resp_header(response, "location") == [~p"/users/log_in"]
      end)
    end

    test "create task", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/tasks",
          task: %{
            name: "Test Task",
            schedule: "* * * * *",
            url: "https://example.com",
            method: "POST",
            headers: %{"Authorization" => "Bearer testtoken"},
            body: "{\"foo\":\"bar\"}"
          }
        )

      assert redirected_to(conn) =~ "/tasks/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) ==
               "Recurring task created successfully!"

      task = Croniq.Repo.get_by!(Croniq.Task, name: "Test Task")
      assert task.url == "https://example.com"
      assert task.method == "POST"
      assert task.headers["Authorization"] == "Bearer testtoken"
      assert task.body == "{\"foo\":\"bar\"}"
    end
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

      assert response
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

      assert response
             |> Floki.parse_document!()
             |> Floki.find("[data-test=rq-log-line]")
             |> Enum.empty?()
    end
  end
end
