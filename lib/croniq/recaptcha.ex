defmodule Croniq.Recaptcha do
  @behaviour Croniq.RecaptchaBehaviour

  def secret_key(:v2) do
    Application.get_env(:croniq, :recaptcha)[:secret_key_v2]
  end

  def secret_key(:v3) do
    Application.get_env(:croniq, :recaptcha)[:secret_key]
  end

  def site_key(:v2) do
    Application.get_env(:croniq, :recaptcha)[:site_key_v2]
  end

  def site_key(:v3) do
    Application.get_env(:croniq, :recaptcha)[:site_key]
  end

  def verify(:v3, token) do
    body = URI.encode_query(%{secret: secret_key(:v3), response: token})
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post("https://www.google.com/recaptcha/api/siteverify", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"success" => true, "score" => score}} when score >= 0.7 ->
            {:ok, score}

          {:ok, %{"success" => true, "score" => score}} when score < 0.7 ->
            {:low_score, score}

          {:ok, %{"success" => false, "error-codes" => ["timeout-or-duplicate"]}} ->
            {:error, "timeout-or-duplicate"}

          {:error, _} ->
            {:error, "Failed to decode JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Unexpected status code: #{code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTPoison error: #{IO.inspect(reason)}"}
    end
  end

  def verify(:v2, token) do
    body = URI.encode_query(%{secret: secret_key(:v2), response: token})
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]

    case HTTPoison.post("https://www.google.com/recaptcha/api/siteverify", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        case Jason.decode(response_body) do
          {:ok, %{"success" => true}} ->
            {:ok, 1.0}

          {:ok, %{"success" => false, "error-codes" => error_codes}} ->
            {:error, "reCAPTCHA verification failed: #{inspect(error_codes)}"}

          {:ok, %{"success" => false}} ->
            {:error, "reCAPTCHA verification failed"}

          {:error, _} ->
            {:error, "Failed to decode JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Unexpected status code: #{code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTPoison error: #{IO.inspect(reason)}"}
    end
  end
end
