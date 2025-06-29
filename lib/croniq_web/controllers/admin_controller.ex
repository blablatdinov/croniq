defmodule CroniqWeb.AdminController do
  use CroniqWeb, :controller

  plug :require_admin

  defp require_admin(conn, _opts) do
    user = conn.assigns[:current_user]
    if user && user.is_admin do
      conn
    else
      conn
      |> put_flash(:error, "You are not authorized to access this page.")
      |> redirect(to: "/")
      |> halt()
    end
  end

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
        |> put_flash(:info, "Пользователь #{user.email} успешно создан и подтвержден.")
        |> redirect(to: ~p"/admin/users")

      {:error, changeset} ->
        render(
          conn,
          :new_user_form,
          changeset: changeset,
          error_message: "Ошибка при создании пользователя"
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

    case Croniq.Accounts.delete_user(user) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Пользователь #{user.email} успешно удален.")
        |> redirect(to: ~p"/admin/users")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Ошибка при удалении пользователя.")
        |> redirect(to: ~p"/admin/users")
    end
  end
end
