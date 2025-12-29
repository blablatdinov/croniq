# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.TasksHTML do
  use CroniqWeb, :html

  embed_templates "tasks_html/*"

  def extract_status(response_body) do
    case response_body do
      nil ->
        "Error"

      _ ->
        response_body
        |> String.split("\n", parts: 2)
        |> Enum.at(0)
        |> String.split(" ")
        |> Enum.at(1)
    end
  end

  def extract_headers(response_body) do
    response_body
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.slice(1..-1//1)
    |> Enum.map(fn header ->
      case String.split(header, ": ", parts: 2) do
        [key, value] -> {key, value}
        _ -> {header, ""}
      end
    end)
  end

  def render_json(response) do
    case Jason.decode(response) do
      {:ok, body} -> Jason.encode!(body, pretty: true)
      _ -> response
    end
  end
end
