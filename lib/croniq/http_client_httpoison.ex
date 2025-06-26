defmodule Croniq.HttpClient.HTTPoison do
  @behaviour Croniq.HttpClient

  @impl true
  def request(request), do: HTTPoison.request(request)
end
