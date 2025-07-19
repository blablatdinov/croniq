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
