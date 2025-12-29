# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule Croniq.Recaptcha do
  @moduledoc """
  Handles reCAPTCHA verification for v2 and v3.

  Provides functions to verify reCAPTCHA tokens and retrieve site/secret keys.
  """
  @behaviour Croniq.RecaptchaBehaviour

  require Logger

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
    Logger.debug("Verifying reCAPTCHA v3 token: #{token}")
    body = URI.encode_query(%{secret: secret_key(:v3), response: token})
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    Logger.debug("[reCAPTCHA v3] Request body: #{inspect(body)}")
    Logger.debug("[reCAPTCHA v3] Request headers: #{inspect(headers)}")

    case HTTPoison.post("https://www.google.com/recaptcha/api/siteverify", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        Logger.debug("[reCAPTCHA v3] Response body: #{inspect(response_body)}")

        case Jason.decode(response_body) do
          {:ok, %{"success" => true, "score" => score}} when score >= 0.7 ->
            Logger.debug("[reCAPTCHA v3] Success, score: #{score}")
            {:ok, score}

          {:ok, %{"success" => true, "score" => score}} when score < 0.7 ->
            Logger.debug("[reCAPTCHA v3] Low score: #{score}")
            {:low_score, score}

          {:ok, %{"success" => false, "error-codes" => ["timeout-or-duplicate"]}} ->
            Logger.error("[reCAPTCHA v3] Timeout or duplicate error")
            {:error, "timeout-or-duplicate"}

          {:error, decode_err} ->
            Logger.error("[reCAPTCHA v3] Failed to decode JSON: #{inspect(decode_err)}")
            {:error, "Failed to decode JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: code, body: response_body}} ->
        Logger.error(
          "[reCAPTCHA v3] Unexpected status code: #{code}, body: #{inspect(response_body)}"
        )

        {:error, "Unexpected status code: #{code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("[reCAPTCHA v3] HTTPoison error: #{inspect(reason)}")
        {:error, "HTTPoison error: #{reason}"}
    end
  end

  def verify(:v2, token) do
    Logger.info("Verifying reCAPTCHA v2 token: #{token}")
    body = URI.encode_query(%{secret: secret_key(:v2), response: token})
    headers = [{"Content-Type", "application/x-www-form-urlencoded"}]
    Logger.debug("[reCAPTCHA v2] Request body: #{inspect(body)}")
    Logger.debug("[reCAPTCHA v2] Request headers: #{inspect(headers)}")

    case HTTPoison.post("https://www.google.com/recaptcha/api/siteverify", body, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        Logger.debug("[reCAPTCHA v2] Response body: #{inspect(response_body)}")

        case Jason.decode(response_body) do
          {:ok, %{"success" => true}} ->
            Logger.debug("[reCAPTCHA v2] Success")
            {:ok, 1.0}

          {:ok, %{"success" => false, "error-codes" => error_codes}} ->
            Logger.error(
              "[reCAPTCHA v2] Verification failed, error codes: #{inspect(error_codes)}"
            )

            {:error, "reCAPTCHA verification failed: #{inspect(error_codes)}"}

          {:ok, %{"success" => false}} ->
            Logger.error("[reCAPTCHA v2] Verification failed (no error codes)")
            {:error, "reCAPTCHA verification failed"}

          {:error, decode_err} ->
            Logger.error("[reCAPTCHA v2] Failed to decode JSON: #{inspect(decode_err)}")
            {:error, "Failed to decode JSON"}
        end

      {:ok, %HTTPoison.Response{status_code: code, body: response_body}} ->
        Logger.error(
          "[reCAPTCHA v2] Unexpected status code: #{code}, body: #{inspect(response_body)}"
        )

        {:error, "Unexpected status code: #{code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("[reCAPTCHA v2] HTTPoison error: #{inspect(reason)}")
        {:error, "HTTPoison error: #{reason}"}
    end
  end
end
