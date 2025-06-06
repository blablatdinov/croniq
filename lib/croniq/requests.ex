defmodule Croniq.Requests do
  import Ecto.Query
  import HTTPoison
  alias Croniq.Repo
  alias Croniq.Task

  def send_request(task_id) do
    task = Repo.get_by!(Task, id: task_id)

    HTTPoison.request!(%HTTPoison.Request{
      method: task.method,
      url: task.url,
      body: task.body,
      headers: task.headers |> Enum.map(fn {key, value} -> {to_string(key), to_string(value)} end)
    })
  end
end
