defmodule CroniqWeb.AdminControllerTest do
  use CroniqWeb.ConnCase

  alias Croniq.Accounts
  alias Croniq.Accounts.User
  import Croniq.AccountsFixtures

  @valid_attrs %{
    "email" => "admin2@example.com",
    "password" => "verylongpassword123",
    "password_confirmation" => "verylongpassword123"
  }

  setup do
    admin = admin_fixture(%{email: "admin@example.com"})
    user = user_fixture(%{email: "user@example.com"})
    {:ok, admin: admin, user: user}
  end

  describe "admin access" do
    test "admin can access users list", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      conn = get(conn, "/admin/users")
      assert html_response(conn, 200) =~ "User Management"
    end

    test "non-admin cannot access users list", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      conn = get(conn, "/admin/users")
      assert redirected_to(conn) == "/"
      assert get_flash(conn, :error) =~ "not authorized"
    end

    test "not logged in cannot access users list", %{conn: conn} do
      conn = get(conn, "/admin/users")
      assert redirected_to(conn) =~ "/users/log_in"
    end
  end

  describe "user creation" do
    test "admin can create user", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      conn = post(conn, "/admin/users", %{user: @valid_attrs})
      assert redirected_to(conn) =~ "/admin/users"
      assert Accounts.get_user_by_email("admin2@example.com")
    end

    test "non-admin cannot create user", %{conn: conn, user: user} do
      conn = log_in_user(conn, user)
      conn = post(conn, "/admin/users", %{user: @valid_attrs})
      assert redirected_to(conn) == "/"
    end
  end

  describe "self-deletion" do
    test "admin cannot see delete button for self", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      conn = get(conn, "/admin/users")
      refute html_response(conn, 200) =~ ~s(href="/admin/users/#{admin.id}")
    end

    test "admin cannot delete self via direct request", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)
      conn = delete(conn, "/admin/users/#{admin.id}")
      assert redirected_to(conn) =~ "/admin/users"
      assert Accounts.get_user_by_email(admin.email)
    end
  end
end
