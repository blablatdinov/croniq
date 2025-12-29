# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

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
