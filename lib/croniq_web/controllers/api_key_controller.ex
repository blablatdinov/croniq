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
