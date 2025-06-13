defmodule CroniqWeb.APIAuthController do
  use CroniqWeb, :controller

  def generate_token(conn, %{"email" => email, "password" => password}) do
    token = Croniq.Accounts.get_user_by_email_and_password(email, password)
    |> Croniq.Accounts.create_user_api_token()
    render(conn, :generate_token, token: token)
  end
end
