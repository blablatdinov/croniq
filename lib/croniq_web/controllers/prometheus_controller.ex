# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.PrometheusController do
  use CroniqWeb, :controller

  def metrics(conn, _params) do
    metrics = TelemetryMetricsPrometheus.Core.scrape()

    conn
    |> put_resp_content_type("text/plain; version=0.0.4")
    |> text(metrics)
  end
end
