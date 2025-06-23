defmodule Croniq.Recaptcha do
  @verify_url "https://www.google.com/recaptcha/api/siteverify"

  def site_key do
    Application.get_env(:croniq, :recaptcha)[:site_key]
  end

  def secret_key do
    Application.get_env(:croniq, :recaptcha)[:secret_key]
  end

  def site_v2_key do
    Application.get_env(:croniq, :recaptcha)[:site_v2_key]
  end

  def secret_v2_key do
    Application.get_env(:croniq, :recaptcha)[:secret_v2_key]
  end

  def verify_recaptcha(token, :v2) do
    verify_recaptcha(token, secret_v2_key(), :v2)
  end

  def verify_recaptcha(token, :v3) do
    verify_recaptcha(token, secret_key(), :v3)
  end

  defp verify_recaptcha(token, secret, version) do
    body = URI.encode_query(%{secret: secret, response: token})
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post(@verify_url, body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"success" => true, "score" => score}} when version == :v3 ->
            if score >= 0.5, do: {:ok, score}, else: {:low_score, score}

          {:ok, %{"success" => true}} when version == :v2 ->
            :ok

          {:ok, %{"success" => false, "error-codes" => errors}} ->
            {:error, errors}

          {:ok, _} ->
            {:error, "Unexpected response"}

          {:error, _} ->
            {:error, "Failed to decode JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Unexpected status code: #{code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP error: #{inspect(reason)}"}
    end
  end
end
