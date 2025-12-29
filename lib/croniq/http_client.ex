# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule Croniq.HttpClient do
  @moduledoc """
  Behaviour for HTTP client implementations.

  Defines the interface for making HTTP requests in the application.
  """
  @callback request(HTTPoison.Request.t()) :: {:ok, HTTPoison.Response.t()} | {:error, any()}
end
