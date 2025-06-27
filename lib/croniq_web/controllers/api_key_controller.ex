defmodule CroniqWeb.ApiKeyController do
  use CroniqWeb, :controller
  import Ecto.Query
  alias Croniq.Accounts
  alias Croniq.Repo
  alias Croniq.Accounts.UserToken

  plug :require_authenticated_user

  def index(conn, _params) do
    user = conn.assigns.current_user

    api_keys =
      Repo.all(from t in UserToken, where: t.user_id == ^user.id and t.context == "api-token")

    api_keys
      |> Enum.map(fn token -> Base.url_encode64(token.token, padding: false) end)
      |> IO.inspect(label: "encoded tokens")
      |> Enum.map(fn token -> Accounts.fetch_user_by_api_token(token) end)
      |> IO.inspect(label: "users")

    render(conn, "index.html", api_keys: api_keys)
  end

  def create(conn, _params) do
    user = conn.assigns.current_user
    Accounts.create_user_api_token(user)

    conn
    |> put_flash(:info, "API key created successfully.")
    |> redirect(to: ~p"/api_keys")
  end

  def delete(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    key = Repo.get_by(UserToken, id: id, user_id: user.id, context: "api-token")

    if key do
      Repo.delete!(key)
      put_flash(conn, :info, "API key deleted.")
    else
      put_flash(conn, :error, "Key not found.")
    end
    |> redirect(to: ~p"/api_keys")
  end

  defp require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user],
      do: conn,
      else: conn |> put_flash(:error, "Please log in.") |> redirect(to: "/users/log_in") |> halt()
  end
end
