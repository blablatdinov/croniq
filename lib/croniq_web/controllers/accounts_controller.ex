defmodule CroniqWeb.AccountsController do
  use CroniqWeb, :controller
  import Plug.Conn
  require Logger

  # Get the reCAPTCHA module from config (allows mocking in tests)
  defp recaptcha_module do
    Application.get_env(:croniq, :recaptcha_module, Croniq.Recaptcha)
  end

  def registration_form(conn, _params) do
    render(
      conn,
      :registration_form,
      changeset: Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{}),
      site_key: recaptcha_module().site_key(:v3),
      error_message: nil
    )
  end

  def registration(conn, params) do
    case params do
      %{"user" => user_params} ->
        recaptcha_result = verify_recaptcha(params)
        handle_registration_result(conn, user_params, recaptcha_result)

      _ ->
        render_registration_form(conn, nil, nil)
    end
  end

  defp verify_recaptcha(params) do
    {recaptcha_version, recaptcha_token} = get_recaptcha_params(params)
    recaptcha_module().verify(recaptcha_version, recaptcha_token)
  end

  defp get_recaptcha_params(params) do
    if Map.has_key?(params, "g-recaptcha-response") do
      {:v2, Map.get(params, "g-recaptcha-response")}
    else
      {:v3, Map.get(params, "recaptcha_token")}
    end
  end

  defp handle_registration_result(conn, user_params, {:ok, _score}) do
    case Croniq.Accounts.register_user(user_params) do
      {:ok, user} ->
        Croniq.Accounts.deliver_user_confirmation_instructions(
          user,
          &url(~p"/users/confirm/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "Account created successfully! Please check your email to confirm your account. You can start creating tasks, but confirmation is required to activate all features."
        )
        |> redirect(to: ~p"/tasks/new")

      {:error, changeset} ->
        render_registration_form(conn, changeset, nil)
    end
  end

  defp handle_registration_result(conn, user_params, {:low_score, score}) do
    Logger.info("low score: #{score}")

    render_registration_form(
      conn,
      create_changeset_with_data(user_params),
      "Please, resolve captcha"
    )
  end

  defp handle_registration_result(conn, user_params, {:error, _details}) do
    render_registration_form(conn, create_changeset_with_data(user_params), nil)
  end

  defp create_changeset_with_data(user_params) do
    Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{
      email: Map.get(user_params, "email", ""),
      password: Map.get(user_params, "password", "")
    })
  end

  defp render_registration_form(conn, changeset, error_message) do
    render(
      conn,
      :registration_form,
      site_key: recaptcha_module().site_key(:v3),
      error_message: error_message,
      changeset: changeset || Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{})
    )
  end

  def log_in_form(conn, _params) do
    render(conn, :log_in,
      changeset: Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{}),
      error_message: nil
    )
  end

  def log_in(conn, %{"user" => %{"email" => email, "password" => password}} = params) do
    case Croniq.Accounts.get_user_by_email_and_password(email, password) do
      nil ->
        render(
          conn,
          :log_in,
          changeset:
            Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{
              email: email,
              password: password
            }),
          error_message: "Invalid email or password"
        )
        |> put_flash(:error, "Invalid email or password")

      user ->
        token = Croniq.Accounts.generate_user_session_token(user)

        conn
        |> put_session(:user_token, token)
        |> configure_session(renew: true)
        |> maybe_put_remember_me_cookie(user, params)
        |> put_flash(:info, get_login_flash_message(params))
        |> redirect(to: get_login_redirect_path(conn, params))
    end
  end

  defp maybe_put_remember_me_cookie(conn, user, %{"user" => %{"remember_me" => "true"}}) do
    put_resp_cookie(conn, "_croniq_web_user_remember_me", to_string(user.id),
      max_age: 60 * 60 * 24 * 365
    )
  end

  defp maybe_put_remember_me_cookie(conn, _user, _params), do: conn

  defp get_login_flash_message(%{"_action" => "registered"}) do
    "Account created successfully"
  end

  defp get_login_flash_message(%{"_action" => "password_updated"}) do
    "Password updated successfully"
  end

  defp get_login_flash_message(_params) do
    "Welcome back!"
  end

  defp get_login_redirect_path(_conn, %{"_action" => "registered"}) do
    ~p"/tasks"
  end

  defp get_login_redirect_path(_conn, %{"_action" => "password_updated"}) do
    ~p"/users/settings"
  end

  defp get_login_redirect_path(conn, _params) do
    get_session(conn, :user_return_to) || ~p"/"
  end

  def forgot_password_form(conn, _params) do
    render(
      conn,
      :forgot_password,
      changeset: Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{}),
      error_message: nil
    )
  end

  def forgot_password(conn, %{"user" => %{"email" => email}}) do
    if user = Croniq.Accounts.get_user_by_email(email) do
      Croniq.Accounts.deliver_user_reset_password_instructions(
        user,
        &url(~p"/users/reset_password/#{&1}")
      )

      Logger.info("Email with token for reset password sended to #{email}")
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/")
  end

  def reset_password_form(conn, %{"token" => token}) do
    case Croniq.Accounts.get_user_by_reset_password_token(token) do
      nil ->
        conn
        |> put_flash(:error, "Reset password link is invalid or it has expired.")
        |> redirect(to: ~p"/")

      _user ->
        render(conn, :reset_password_form,
          token: token,
          changeset: Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{})
        )
    end
  end

  def reset_password(conn, %{"token" => token, "user" => user_params}) do
    case Croniq.Accounts.get_user_by_reset_password_token(token) do
      nil ->
        conn
        |> put_flash(:error, "Reset password link is invalid or it has expired.")
        |> redirect(to: ~p"/")

      user ->
        case Croniq.Accounts.reset_user_password(user, user_params) do
          {:ok, _} ->
            conn
            |> put_flash(:info, "Password reset successfully.")
            |> redirect(to: ~p"/users/log_in")

          {:error, changeset} ->
            render(conn, :reset_password_form, token: token, changeset: changeset)
        end
    end
  end

  def confirm(conn, %{"token" => token}) do
    case Croniq.Accounts.confirm_user(token) do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Account confirmed successfully.")
        |> redirect(to: ~p"/users/log_in")

      :error ->
        conn
        |> put_flash(:error, "Confirmation link is invalid or it has expired.")
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def confirmation_instructions_form(conn, _params) do
    email = conn.assigns[:current_user] && conn.assigns.current_user.email

    changeset =
      Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{email: email || ""})

    render(conn, :confirmation_instructions_form, changeset: changeset)
  end

  def send_confirmation_instructions(conn, %{"user" => %{"email" => email}}) do
    if user = Croniq.Accounts.get_user_by_email(email) do
      Croniq.Accounts.deliver_user_confirmation_instructions(
        user,
        &url(~p"/users/confirm/#{&1}")
      )
    end

    info =
      "If your email is in our system and it has not been confirmed yet, you will receive an email with instructions shortly."

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/users/log_in")
  end
end
