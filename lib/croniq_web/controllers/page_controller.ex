defmodule CroniqWeb.PageController do
  use CroniqWeb, :controller
  alias Croniq.Repo
  alias Croniq.Task
  import Croniq.Requests
  import Crontab.CronExpression
  import Logger

  def home(conn, _params) do
    render(conn, :home)
  end
end
