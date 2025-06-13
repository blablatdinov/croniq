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

    try do
      response =
        HTTPoison.request!(%HTTPoison.Request{
          method: task.method,
          url: task.url,
          body: task.body,
          headers:
            task.headers |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
        })

      Logger.info("Request for task #{task.id} completed",
        status_code: response.status_code,
        response_body: IO.inspect(response.body),
        response_headers: IO.inspect(response.headers)
      )

      response
    rescue
      error ->
        Logger.error("Request for task #{task.id} failed",
          error: IO.inspect(error),
          stacktrace: IO.inspect(__STACKTRACE__)
        )

        reraise error, __STACKTRACE__
    end
  end
end
