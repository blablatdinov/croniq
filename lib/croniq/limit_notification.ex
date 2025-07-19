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

defmodule Croniq.LimitNotification do
  @moduledoc """
  Stores information about whether a user has been notified about exceeding their request limit today.
  Uses Redis for storage (keys like limit_notification_sent:<user_id> with 1 day TTL).
  """
  @prefix "limit_notification_sent"
  @max_retries 3

  defp redis_command_with_retry(command, retries \\ @max_retries)
  defp redis_command_with_retry(_command, 0), do: {:error, :max_retries_exceeded}

  defp redis_command_with_retry(command, retries) do
    case Croniq.Redis.Pool.command(command) do
      {:ok, result} ->
        {:ok, result}

      {:error, _} ->
        Process.sleep(100)
        redis_command_with_retry(command, retries - 1)
    end
  end

  def notified_today?(user_id) do
    key = "#{@prefix}:#{user_id}"

    case redis_command_with_retry(["GET", key]) do
      {:ok, date} when is_binary(date) ->
        date == Date.to_iso8601(Date.utc_today())

      {:ok, _} ->
        false

      {:error, _} ->
        false
    end
  end

  def mark_notified(user_id) do
    key = "#{@prefix}:#{user_id}"
    today = Date.to_iso8601(Date.utc_today())
    # TTL 1 день
    case redis_command_with_retry(["SET", key, today, "EX", "86400"]) do
      {:ok, _} -> :ok
      {:error, _} -> :error
    end
  end

  def clear do
    {:ok, keys} = Croniq.Redis.Pool.command(["KEYS", "#{@prefix}:*"])
    Enum.each(keys, fn key -> Croniq.Redis.Pool.command(["DEL", key]) end)
    :ok
  end
end
