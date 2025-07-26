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

      assert length(Floki.find(parsed, "[data-test=task-line]")) == 10
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

      conn
      |> get(~p"/tasks/#{task.id}/edit")
      |> html_response(200)

      assert Plug.Conn.get_resp_header(conn, "location") == [~p"/tasks/#{task.id}/edit"]

      assert %{
               name: "new name",
               headers: %{"Authorization" => "newToken"}
             } = Croniq.Repo.get_by(Croniq.Task, id: task.id) |> Map.from_struct()
    end

    test "edit task contain schedule", %{conn: conn, user: user} do
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
        |> Floki.find("[data-test=schedule-input]")

      [{"input", attrs, _}] = elem
      input_value = Enum.into(attrs, %{})["value"]

      assert input_value ==
               "*/5 * * * *"
    end

    test "edit task contain headers", %{conn: conn, user: user} do
      [task] = task_list_for_user(user)

      conn =
        conn
        |> log_in_user(user)
        |> put(~p"/tasks/#{task.id}",
          task: %{
            name: "new name",
            headers: %{"MyHeader" => "MyValue"},
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
        |> Floki.find("[data-test=headers-input]")

      [{"textarea", _attrs, [input_value]}] = elem
      input_value = input_value |> String.trim() |> Floki.parse_fragment!() |> Floki.text()

      assert input_value ==
               "{\"MyHeader\":\"MyValue\"}"
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

    test "deletion request log", %{conn: conn, user_token: user_token, user: user} do
      [task] = task_list_for_user(user)
      [rq_log] = requests_log(task)

      conn
      |> put_session(:user_token, user_token)
      |> delete(~p"/tasks/#{task.id}")
      |> html_response(302)

      refute Croniq.Repo.exists?(from t in Croniq.Task, where: t.id == ^task.id)
      refute Croniq.Repo.exists?(from rql in Croniq.RequestLog, where: rql.id == ^rq_log.id)
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

    test "create task with status", %{conn: conn, user: user} do
      conn =
        conn
        |> log_in_user(user)
        |> post(~p"/tasks",
          task: %{
            name: "Test Task 2",
            schedule: "* * * * *",
            url: "https://example.com",
            method: "POST",
            headers: %{"Authorization" => "Bearer testtoken2"},
            body: "{\"foo\":\"bar\"}",
            status: "disabled"
          }
        )

      assert redirected_to(conn) =~ "/tasks/"

      task = Croniq.Repo.get_by!(Croniq.Task, name: "Test Task 2")
      assert task.status == "disabled"
    end

    test "edit task status", %{conn: conn, user: user} do
      [task] = task_list_for_user(user)

      conn =
        conn
        |> log_in_user(user)
        |> put(~p"/tasks/#{task.id}",
          task: %{
            name: "edited name",
            headers: %{"Authorization" => "editedToken"},
            schedule: "*/5 * * * *",
            status: "disabled"
          }
        )

      html_response(conn, 302)

      updated_task = Croniq.Repo.get_by!(Croniq.Task, id: task.id)
      assert updated_task.status == "disabled"
      assert updated_task.name == "edited name"
    end

    test "Pagination: only page_size tasks are shown on a page", %{
      conn: conn,
      user_token: user_token,
      user: user
    } do
      tasks = task_list_for_user(user, 25)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks?page=2&page_size=10")
        |> html_response(200)

      parsed = Floki.parse_document!(response)
      # There should be 10 tasks on the second page
      assert length(Floki.find(parsed, "[data-test=task-line]")) == 10
      # The first task on the second page should be the 11th in order
      assert Floki.text(Floki.find(parsed, "[data-test=id-cell]") |> Enum.at(0)) |> String.trim() ==
               Integer.to_string(Enum.at(tasks, 10).id)
    end

    test "Pagination: page_size selection works correctly", %{
      conn: conn,
      user_token: user_token,
      user: user
    } do
      task_list_for_user(user, 55)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks?page=1&page_size=50")
        |> html_response(200)

      parsed = Floki.parse_document!(response)
      # There should be 50 tasks on the first page
      assert length(Floki.find(parsed, "[data-test=task-line]")) == 50
    end

    test "Pagination: selected page_size is shown in select", %{
      conn: conn,
      user_token: user_token,
      user: user
    } do
      task_list_for_user(user, 10)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks?page=1&page_size=20")
        |> html_response(200)

      parsed = Floki.parse_document!(response)

      selected =
        Floki.find(parsed, "select[name=page_size] option[selected]") |> Floki.attribute("value")

      assert selected == ["20"]
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
      assert length(Floki.find(parsed, "[data-test=rq-log-line]")) == 10
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

    test "Pagination: only page_size logs are shown on a page", %{
      conn: conn,
      user_token: user_token,
      user: user
    } do
      [task] = task_list_for_user(user)
      logs = requests_log(task, 25)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/#{task.id}/requests-log?page=2&page_size=10")
        |> html_response(200)

      parsed = Floki.parse_document!(response)
      assert length(Floki.find(parsed, "[data-test=rq-log-line]")) == 10

      first_log_id_on_page_2 =
        Floki.text(
          Floki.find(parsed, "[data-test=rq-log-line]")
          |> Enum.at(0)
          |> Floki.find("td")
          |> Enum.at(0)
          |> Floki.find("a")
          |> Enum.at(0)
        )
        |> String.trim()

      assert first_log_id_on_page_2 != Integer.to_string(Enum.at(logs, 0).id)
    end

    test "Request log pagination: null response body", %{
      conn: conn,
      user_token: user_token,
      user: user
    } do
      [task] = task_list_for_user(user)

      Croniq.RequestLog.create_rq_log(%{
        "task_id" => task.id,
        "request" => "string",
        "response" => nil,
        "duration" => 430,
        "error" => ""
      })

      conn
      |> put_session(:user_token, user_token)
      |> get(~p"/tasks/#{task.id}/requests-log")
      |> html_response(200)
    end

    test "Pagination: page_size selection works correctly", %{
      conn: conn,
      user_token: user_token,
      user: user
    } do
      [task] = task_list_for_user(user)
      requests_log(task, 55)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/#{task.id}/requests-log?page=1&page_size=50")
        |> html_response(200)

      parsed = Floki.parse_document!(response)
      # There should be 50 logs on the first page
      assert length(Floki.find(parsed, "[data-test=rq-log-line]")) == 50
    end

    test "Pagination: selected page_size is shown in select", %{
      conn: conn,
      user_token: user_token,
      user: user
    } do
      [task] = task_list_for_user(user)
      requests_log(task, 10)

      response =
        conn
        |> put_session(:user_token, user_token)
        |> get(~p"/tasks/#{task.id}/requests-log?page=1&page_size=20")
        |> html_response(200)

      parsed = Floki.parse_document!(response)

      selected =
        Floki.find(parsed, "select[name=page_size] option[selected]") |> Floki.attribute("value")

      assert selected == ["20"]
    end
  end
end
