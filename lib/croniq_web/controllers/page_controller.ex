defmodule CroniqWeb.PageController do
  use CroniqWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def docs(conn, _params) do
    render(conn, :docs)
  end
end
