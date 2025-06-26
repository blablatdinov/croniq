defmodule Croniq.HttpClient do
  @callback request(HTTPoison.Request.t()) :: {:ok, HTTPoison.Response.t()} | {:error, any()}
end
