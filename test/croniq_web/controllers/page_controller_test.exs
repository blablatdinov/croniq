defmodule CroniqWeb.PageControllerTest do
  use CroniqWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Croniq — Open-Source Cron Scheduler"
  end
end
