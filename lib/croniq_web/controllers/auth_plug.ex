defmodule CroniqWeb.AuthPlug do
  import Plug.Conn
  import Phoenix.Controller
  alias Phoenix.LiveView.Route
  alias CroniqWeb.Router.Helpers, as: Routes

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn)
    if user_id do
      user = Croniq.Accounts.get_user!(user_id)
      assign(conn, :current_user, user)
    else
      conn
      |> put_flash(:error, "Please log in to access this page")
      |> redirect(to: Routes.session_path(conn, :new))
      |> halt()
    end
  end

end
