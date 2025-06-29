defmodule CroniqWeb.Plugs.RequireAdmin do
  @moduledoc """
  Plug to restrict access to admin-only routes. Redirects non-admin users to the home page with an error message.
  """
  import Plug.Conn
  import Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
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
end
