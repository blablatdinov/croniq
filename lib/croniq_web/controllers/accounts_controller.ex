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
        {recaptcha_version, recaptcha_token} =
          cond do
            Map.has_key?(params, "g-recaptcha-response") ->
              IO.inspect(Map.get(params, "g-recaptcha-response"), label: "v2_token")
              {:v2, Map.get(params, "g-recaptcha-response")}

            true ->
              {:v3, Map.get(params, "recaptcha_token")}
          end

        case recaptcha_module().verify(recaptcha_version, recaptcha_token) do
          {:ok, _score} ->
            case Croniq.Accounts.register_user(user_params) do
              {:ok, _user} ->
                conn
                |> put_flash(:info, "Account created successfully!")
                |> redirect(to: ~p"/tasks/new")

              {:error, %Ecto.Changeset{} = changeset} ->
                IO.inspect(changeset)

                render(
                  conn,
                  :registration_form,
                  site_key: recaptcha_module().site_key(:v3),
                  error_message: nil,
                  changeset: changeset
                )
            end

          {:low_score, score} ->
            Logger.info("low score: #{score}")
            IO.puts("site_v2_key: #{recaptcha_module().site_key(:v2)}")

            render(
              conn,
              :registration_form,
              site_key: recaptcha_module().site_key(:v3),
              error_message: "Please, resolve catcha",
              site_key_v2: recaptcha_module().site_key(:v2),
              changeset:
                Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{
                  email: Map.get(user_params, "email", ""),
                  password: Map.get(user_params, "password", "")
                })
            )

          {:error, details} ->
            Logger.info("Error, details: #{details}")

            render(
              conn,
              :registration_form,
              site_key: recaptcha_module().site_key(:v3),
              error_message: nil,
              changeset:
                Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{
                  email: Map.get(user_params, "email", ""),
                  password: Map.get(user_params, "password", "")
                })
            )
        end

      _ ->
        render(
          conn,
          :registration_form,
          site_key: recaptcha_module().site_key(:v3),
          error_message: nil,
          changeset: Croniq.Accounts.change_user_registration(%Croniq.Accounts.User{})
        )
    end
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
    put_resp_cookie(conn, "_croniq_web_user_remember_me", to_string(user.id), max_age: 60 * 60 * 24 * 365)
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

  defp get_login_redirect_path(conn, %{"_action" => "registered"}) do
    ~p"/tasks"
  end

  defp get_login_redirect_path(conn, %{"_action" => "password_updated"}) do
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
    end

    info =
      "If your email is in our system, you will receive instructions to reset your password shortly."

    conn
    |> put_flash(:info, info)
    |> redirect(to: ~p"/")
  end
end
