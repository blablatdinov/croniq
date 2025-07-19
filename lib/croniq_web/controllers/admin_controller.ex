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

defmodule CroniqWeb.AdminController do
  use CroniqWeb, :controller

  def new_user_form(conn, _params) do
    render(
      conn,
      :new_user_form,
      changeset: Croniq.Accounts.change_admin_user_registration(%Croniq.Accounts.User{}),
      error_message: nil
    )
  end

  def create_user(conn, %{"user" => user_params}) do
    case Croniq.Accounts.create_user_by_admin(user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User #{user.email} was successfully created and confirmed.")
        |> redirect(to: ~p"/admin/users")

      {:error, changeset} ->
        render(
          conn,
          :new_user_form,
          changeset: changeset,
          error_message: "Error creating user"
        )
    end
  end

  def create_user(conn, _params) do
    render_new_user_form(conn, nil, nil)
  end

  defp render_new_user_form(conn, changeset, error_message) do
    render(
      conn,
      :new_user_form,
      changeset:
        changeset || Croniq.Accounts.change_admin_user_registration(%Croniq.Accounts.User{}),
      error_message: error_message
    )
  end

  def users_list(conn, _params) do
    users = Croniq.Accounts.list_users()
    render(conn, :users_list, users: users)
  end

  def delete_user(conn, %{"id" => id}) do
    user = Croniq.Accounts.get_user!(id)

    if user.id == conn.assigns.current_user.id do
      conn
      |> put_flash(:error, "You cannot delete yourself.")
      |> redirect(to: ~p"/admin/users")
    else
      case Croniq.Accounts.delete_user(user) do
        {:ok, _} ->
          conn
          |> put_flash(:info, "User #{user.email} was successfully deleted.")
          |> redirect(to: ~p"/admin/users")

        {:error, _changeset} ->
          conn
          |> put_flash(:error, "Error deleting user.")
          |> redirect(to: ~p"/admin/users")
      end
    end
  end
end
