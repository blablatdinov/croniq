defmodule Croniq.HttpClient.HTTPoison do
  @moduledoc """
  HTTPoison implementation of the HttpClient behaviour.

  Wraps HTTPoison library to provide HTTP request functionality.
  """
  @behaviour Croniq.HttpClient

  @impl true
  def request(request), do: HTTPoison.request(request)
end
