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
  import Ecto.Query

  def send_request(task_id) do
    task = Repo.get_by!(Task, id: task_id)
    start_time = System.monotonic_time(:millisecond)

    now = DateTime.utc_now()
    midnight = %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}

    count =
      Croniq.RequestLog
      |> where([r], r.task_id == ^task_id and r.inserted_at > ^midnight)
      |> select([r], count(r.id))
      |> Repo.one()

    if count >= 100 do
      Logger.error("Request limit (100 per day) exceeded for task #{task.id}")
      :error
    else
      request = %HTTPoison.Request{
        method: task.method,
        url: task.url,
        body: task.body,
        headers: Enum.map(task.headers, fn {key, value} -> {to_string(key), to_string(value)} end)
      }

      http_client = Application.get_env(:croniq, :http_client, Croniq.HttpClient.HTTPoison)

      Logger.info("Sending request for task: #{task.id}")

      case http_client.request(request) do
        {:ok, response} ->
          Logger.info(
            Enum.join(
              [
                "Request for task #{task.id} completed, status_code=#{response.status_code}",
                "response_body=#{response.body}",
                "response_headers=#{headers_str(response.headers)}"
              ],
              " "
            )
          )

          duration = System.monotonic_time(:millisecond) - start_time
          log_successful_response(request, response, duration, task)

        {:error, error} ->
          Logger.error("Request for task #{task.id} failed, error=#{inspect(error)}")

          duration = System.monotonic_time(:millisecond) - start_time
          log_failed_response(request, error, duration, task)
      end

      :ok
    end
  end

  def log_successful_response(request, response, duration, task) do
    %Croniq.RequestLog{}
    |> Croniq.RequestLog.changeset(%{
      request: format_request(request),
      response: format_response(response),
      duration: duration,
      error: nil,
      task_id: task.id
    })
    |> Repo.insert!()
  end

  def log_failed_response(request, error, duration, task) do
    %Croniq.RequestLog{}
    |> Croniq.RequestLog.changeset(%{
      request: format_request(request),
      response: nil,
      duration: duration,
      error: to_string(error.reason),
      task_id: task.id
    })
    |> Repo.insert!()
  end

  def format_request(request) do
    """
    #{request.method} #{URI.parse(request.url).path} HTTP/1.1
    HOST: #{URI.parse(request.url).host}
    #{headers_str(request.headers)}

    #{request.body || ""}
    """
    |> String.trim()
  end

  def format_response(response) do
    body =
      case Enum.find(response.headers, fn {k, v} ->
             String.downcase(k) == "content-encoding" and String.downcase(v) == "gzip"
           end) do
        nil ->
          response.body || ""

        _ ->
          try do
            decompressed = :zlib.gunzip(response.body)
            if is_binary(decompressed), do: decompressed, else: response.body || ""
          rescue
            _ -> response.body || ""
          end
      end

    """
    HTTP/1.1 #{response.status_code} #{Plug.Conn.Status.reason_atom(response.status_code)}
    #{headers_str(response.headers)}

    #{body}
    """
    |> String.trim()
  end

  def headers_str(headers) do
    Enum.map_join(
      headers,
      "\r\n",
      fn {k, v} -> "#{k}: #{v}" end
    )
  end
end
