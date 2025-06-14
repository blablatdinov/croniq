defmodule Croniq.Requests do
  import Ecto.Query
  import HTTPoison
  alias Croniq.Repo
  alias Croniq.Task
  import Logger

  def send_request(task_id) do
    task = Repo.get_by!(Task, id: task_id)

    Logger.info("Sending request for task #{task.id}",
      method: task.method,
      url: task.url,
      task: IO.inspect(task, pretty: true)
    )

    start_time = System.monotonic_time(:millisecond)

    request = %HTTPoison.Request{
      method: task.method,
      url: task.url,
      body: task.body,
      headers: task.headers |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
    }

    case HTTPoison.request(request) do
      {:ok, response} ->
        Logger.info("Request for task #{task.id} completed",
          status_code: response.status_code,
          response_body: IO.inspect(response.body),
          response_headers: IO.inspect(response.headers)
        )

        duration = System.monotonic_time(:millisecond) - start_time
        log_successful_response(request, response, duration, task)

      {:error, error} ->
        Logger.error("Request for task #{task.id} failed",
          error: IO.inspect(error)
        )

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
    |> Croniq.Requests.Log.changeset(%{
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
    #{request.method} #{request.url}
    Headers: #{inspect(request.headers)}
    Body: #{request.body || "<empty>"}
    """
  end

  defp format_response(response) do
    """
    Status: #{response.status_coe}
    Headers: #{inspect(response.headers)}
    Body: #{response.body || "<empty>"}
    """
  end
end
