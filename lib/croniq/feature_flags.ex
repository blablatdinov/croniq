# The MIT License (MIT).
#
# Copyright (c) 2025 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

defmodule Croniq.FeatureFlags do
  @moduledoc """
  Module for managing feature flags in the application.

  Allows enabling/disabling various features via config or environment variables.
  """

  @doc """
  Checks if user registration is enabled.

  ## Examples

      iex> Croniq.FeatureFlags.registration_enabled?()
      true
  """
  def registration_enabled? do
    case Application.get_env(:croniq, :registration_enabled, true) do
      nil -> true
      value -> value
    end
  end

  @doc """
  Checks if a given feature flag is enabled.

  ## Parameters
    * `flag_name` - feature flag name (atom)
    * `default` - default value (default: false)

  ## Examples

      iex> Croniq.FeatureFlags.enabled?(:some_feature)
      false

      iex> Croniq.FeatureFlags.enabled?(:some_feature, true)
      true
  """
  def enabled?(flag_name, default \\ false) do
    Application.get_env(:croniq, flag_name, default)
  end
end
