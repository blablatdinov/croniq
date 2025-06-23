defmodule Croniq.Recaptcha do

  @verify_url "https://www.google.com/recaptcha/api/siteverify"

  def site_key do
    Application.get_env(:croniq, :recaptcha)[:site_key]
  end

  def secret_key do
    Application.get_env(:croniq, :recaptcha)[:secret_key]
  end

  def verify_recaptcha(token) do
    body = URI.encode_query(%{
      secret: secret_key(),
      response: token
    })

    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    IO.inspect(body, label: "recatcha request")
    case HTTPoison.post(@verify_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        IO.inspect(response_body, label: "recatcha response")
        case Jason.decode(response_body) do
          {:ok, %{"success" => true, "score" => score}} when score >= 0.5 ->
            {:ok, score}

          {:ok, _response} ->
            IO.inspect(_response)
            {:error, "Low score or failure"}

          {:error, _} ->
            {:error, "Failed to decode JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Unexpected status code: #{code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTPoison error: #{inspect(reason)}"}
    end
  end
end
