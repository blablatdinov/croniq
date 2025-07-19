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
