defmodule CroniqWeb.TasksHTML do
  use CroniqWeb, :html

  embed_templates "tasks_html/*"

  def extract_status(response) do
    response
    |> String.split("\n", parts: 2)
    |> Enum.at(0)
    |> String.split(" ")
    |> Enum.at(1)
  end

  def extract_headers(response) do
    response
    |> String.split("\n")
    |> Enum.map(&String.trim/1)
    |> Enum.slice(1..-1)
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
