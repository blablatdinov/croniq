# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.PageController do
  use CroniqWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end

  def docs(conn, _params) do
    auth_json =
      Jason.encode!(%{"email" => "your@email.com", "password" => "yourpassword"}, pretty: true)

    create_task_json =
      Jason.encode!(
        %{
          "name" => "My API Call",
          "schedule" => "* * * * *",
          "url" => "https://api.example.com/endpoint",
          "method" => "POST",
          "headers" => %{"Content-Type" => "application/json"},
          "body" => "{\"foo\":\"bar\"}"
        },
        pretty: true
      )

    update_task_json =
      Jason.encode!(
        %{
          "name" => "Updated Name",
          "schedule" => "*/5 * * * *",
          "url" => "https://api.example.com/endpoint",
          "method" => "GET"
        },
        pretty: true
      )

    delayed_task_json =
      Jason.encode!(
        %{
          "name" => "One-time task",
          "url" => "https://example.com",
          "method" => "POST",
          "headers" => %{},
          "body" => "",
          "scheduled_at" => "2024-07-01T18:00:00Z"
        },
        pretty: true
      )

    render(conn, :docs,
      auth_json: auth_json,
      create_task_json: create_task_json,
      update_task_json: update_task_json,
      delayed_task_json: delayed_task_json
    )
  end
end
