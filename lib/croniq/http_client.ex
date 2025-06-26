defmodule Croniq.HttpClient do
  @moduledoc """
  Behaviour for HTTP client implementations.

  Defines the interface for making HTTP requests in the application.
  """
  @callback request(HTTPoison.Request.t()) :: {:ok, HTTPoison.Response.t()} | {:error, any()}
end
