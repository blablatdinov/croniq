defmodule CroniqWeb.AccountsController do
  use CroniqWeb, :controller
  import Plug.Conn

  def registration_form(conn, _params) do
    render(conn, :registration_form,
      changeset: Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{})
    )
  end

  def registration(conn, %{"user" => user_params}) do
    case Croniq.Accounts.register_user(user_params) do
      {:ok, user} ->
        {:ok, _} =
          conn
          |> put_flash(:info, "Account created successfully!")
          |> redirect(to: ~p"/tasks/new")

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset)
        render(conn, :registration_form, changeset: changeset)
    end
  end

  def log_in_form(conn, _params) do
    render(conn, :log_in,
      changeset: Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{}),
      error_message: nil
    )
  end

  def log_in(conn, %{"user" => %{"email" => email, "password" => password}}) do
    case Croniq.Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        render(
          conn, :log_in,
          changeset: Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{
            email: email,
            password: password,
          }),
          error_message: "Invalid email or password"
          )

      user ->
        token = Croniq.Accounts.generate_user_session_token(user)
        conn
        |> put_session(:user_token, token)
        |> configure_session(renew: true)
        |> redirect(to: ~p"/tasks")
    end
  end
end
