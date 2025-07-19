# The MIT License (MIT).
#
# Copyright (c) 2025 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

defmodule CroniqWeb.AdminControllerTest do
  use CroniqWeb.ConnCase

  alias Croniq.Accounts
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
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "not authorized"
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

    test "shows error for short password", %{conn: conn, admin: admin} do
      conn = log_in_user(conn, admin)

      attrs = %{
        "email" => "shortpass@example.com",
        "password" => "short",
        "password_confirmation" => "short"
      }

      conn = post(conn, "/admin/users", %{user: attrs})
      html = html_response(conn, 200)
      assert html =~ "should be at least 12 character(s)"
      assert html =~ "Create New User"
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

  describe "user deletion" do
    test "admin can delete another user", %{conn: conn, admin: admin, user: user} do
      conn = log_in_user(conn, admin)
      conn = delete(conn, "/admin/users/#{user.id}")
      assert redirected_to(conn) =~ "/admin/users"
      refute Accounts.get_user_by_email(user.email)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "successfully deleted"
    end
  end
end
