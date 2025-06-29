defmodule Croniq.FeatureFlagsTest do
  use ExUnit.Case, async: true

  alias Croniq.FeatureFlags

  describe "registration_enabled?/0" do
    test "returns true by default" do
      # Сбрасываем конфигурацию для теста
      Application.put_env(:croniq, :registration_enabled, nil)
      assert FeatureFlags.registration_enabled?() == true
    end

    test "returns false when explicitly disabled" do
      Application.put_env(:croniq, :registration_enabled, false)
      assert FeatureFlags.registration_enabled?() == false
    end

    test "returns true when explicitly enabled" do
      Application.put_env(:croniq, :registration_enabled, true)
      assert FeatureFlags.registration_enabled?() == true
    end
  end

  describe "enabled?/2" do
    test "returns false by default for unknown flags" do
      assert FeatureFlags.enabled?(:unknown_flag) == false
    end

    test "returns custom default value" do
      assert FeatureFlags.enabled?(:unknown_flag, true) == true
    end

    test "returns configured value" do
      Application.put_env(:croniq, :test_flag, true)
      assert FeatureFlags.enabled?(:test_flag) == true
    end
  end
end
