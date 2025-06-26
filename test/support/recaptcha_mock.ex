defmodule Croniq.RecaptchaMock do
  @moduledoc """
  Mock for Croniq.Recaptcha module for testing
  """
  @behaviour Croniq.RecaptchaBehaviour

  def verify(:v3, _token), do: {:ok, 0.9}
  def verify(:v2, _token), do: {:ok, 1.0}

  def site_key(:v3), do: "test_site_key"
  def site_key(:v2), do: "test_site_key_v2"

  def secret_key(:v3), do: "test_secret_key"
  def secret_key(:v2), do: "test_secret_key_v2"
end
