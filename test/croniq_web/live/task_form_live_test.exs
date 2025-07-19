defmodule CroniqWeb.TaskFormLiveTest do
  use CroniqWeb.ConnCase
  import Phoenix.LiveViewTest
  import Croniq.AccountsFixtures

  setup do
    user = confirmed_user_fixture()
    %{user: user}
  end

  describe "Task form live view" do
        test "redirects if user is not authenticated", %{conn: conn} do
      assert {:error, {:redirect, %{to: "/users/log_in"}}} =
               live(conn, ~p"/create-task")
    end

    test "redirects if user email is not confirmed", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      assert {:error, {:redirect, %{to: "/tasks"}}} =
               live(conn, ~p"/create-task")
    end

        test "shows form for confirmed user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/create-task")

      assert has_element?(view, "h1", "Create New Task")
      assert has_element?(view, "input[name='task[name]']")
      assert has_element?(view, "input[name='task[url]']")
      assert has_element?(view, "select[name='task[method]']")
    end

            test "toggles task type fields", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/create-task")

      # Initially recurring fields should be visible
      assert has_element?(view, "#recurring-fields")

      # Click on delayed task type
      view
      |> element("input[value='delayed']")
      |> render_click()

      # Now delayed fields should be visible
      assert has_element?(view, "#delayed-fields")
    end

            test "validates form on change", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/create-task")

      # Fill in required fields
      view
      |> form("#task-form", task: %{name: "Test Task", url: "https://example.com"})
      |> render_change()

      # Should not show validation errors for valid data
      refute has_element?(view, ".error")
    end

            test "creates recurring task successfully", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/create-task")

      task_params = %{
        name: "Test Recurring Task",
        url: "https://example.com",
        method: "GET",
        schedule: "*/5 * * * *",
        status: "active"
      }

      view
      |> form("#task-form", task: task_params)
      |> render_submit()

      # Should redirect to edit page
      assert_redirect(view, ~p"/tasks/1/edit")
    end

            test "creates delayed task successfully", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)

      {:ok, view, _html} = live(conn, ~p"/create-task")

      # Switch to delayed task type
      view
      |> element("input[value='delayed']")
      |> render_click()

      future_time = DateTime.utc_now() |> DateTime.add(3600, :second) |> DateTime.to_iso8601()

      task_params = %{
        name: "Test Delayed Task",
        url: "https://example.com",
        method: "POST",
        scheduled_at: future_time,
        status: "active"
      }

      view
      |> form("#task-form", task: task_params)
      |> render_submit()

      # Should redirect to edit page
      assert_redirect(view, ~p"/tasks/1/edit")
    end
  end
end
