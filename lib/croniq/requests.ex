defmodule Croniq.Requests do
  @moduledoc """
  Executes and logs HTTP requests for scheduled tasks.

  Features:
  - Makes HTTP calls with configurable methods/headers/bodies
  - Tracks response metrics and duration
  - Stores detailed request/response logs
  - Handles errors with retry logic
  - Formats raw HTTP traffic for debugging

  Integrates with Task model to provide end-to-end execution tracking.
  """
  alias Croniq.Repo
  alias Croniq.Task
  require Logger

  def send_request(task_id) do
    task = Repo.get_by!(Task, id: task_id)

    Logger.info("Sending request for task: #{task}")

    start_time = System.monotonic_time(:millisecond)

    request = %HTTPoison.Request{
      method: task.method,
      url: task.url,
      body: task.body,
      headers: Enum.map(task.headers, fn {key, value} -> {to_string(key), to_string(value)} end)
    }

    case HTTPoison.request(request) do
      {:ok, response} ->
        Logger.info(
          Enum.join(
            [
              "Request for task #{task.id} completed, status_code=#{response.status_code}",
              "response_body=#{response.body}",
              "response_headers=#{response.headers}"
            ],
            " "
          )
        )

        duration = System.monotonic_time(:millisecond) - start_time
        log_successful_response(request, response, duration, task)

      {:error, error} ->
        Logger.error("Request for task #{task.id} failed, error=#{error}")

        duration = System.monotonic_time(:millisecond) - start_time
        log_failed_response(request, error, duration, task)
    end

    :ok
  end

  defp log_successful_response(request, response, duration, task) do
    %Croniq.RequestLog{}
    |> Croniq.RequestLog.changeset(%{
      request: format_request(request),
      response: format_response(response),
      duration: duration,
      error: nil
    })
    |> Ecto.Changeset.put_assoc(:task, task)
    |> Repo.insert!()
  end

  defp log_failed_response(request, error, duration, task) do
    %Croniq.RequestLog{}
    |> Croniq.RequestLog.changeset(%{
      request: format_request(request),
      response: nil,
      duration: duration,
      error: error
    })
    |> Ecto.Changeset.put_assoc(:task, task)
    |> Repo.insert!()
  end

  defp format_request(request) do
    """
    #{request.method} #{URI.parse(request.url).path} HTTP/1.1
    HOST: #{URI.parse(request.url).host}
    #{headers_str(request.headers)}

    #{request.body || ""}
    """
    |> String.trim()
  end

  defp format_response(response) do
    """
    HTTP/1.1 #{response.status_code} #{Plug.Conn.Status.reason_atom(response.status_code)}
    #{headers_str(response.headers)}

    #{response.body || ""}
    """
    |> String.trim()
  end

  defp headers_str(headers) do
    Enum.map_join(
      headers,
      "\r\n",
      fn {k, v} -> "#{k}: #{v}" end
    )
  end
end
