# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule Croniq.RecaptchaBehaviour do
  @moduledoc """
  Behaviour for reCAPTCHA verification
  """
  @callback verify(atom(), String.t()) ::
              {:ok, float()} | {:low_score, float()} | {:error, String.t()}
  @callback site_key(atom()) :: String.t()
  @callback secret_key(atom()) :: String.t()
end
