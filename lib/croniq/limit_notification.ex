defmodule Croniq.LimitNotification do
  @moduledoc """
  Stores information about whether a user has been notified about exceeding their request limit today.
  Uses Redis for storage (keys like limit_notification_sent:<user_id> with 1 day TTL).
  """
  @prefix "limit_notification_sent"

  def notified_today?(user_id) do
    key = "#{@prefix}:#{user_id}"

    case Redix.command!(:redix, ["GET", key]) do
      date when is_binary(date) -> date == Date.to_iso8601(Date.utc_today())
      _ -> false
    end
  end

  def mark_notified(user_id) do
    key = "#{@prefix}:#{user_id}"
    today = Date.to_iso8601(Date.utc_today())
    # TTL 1 день
    Redix.command!(:redix, ["SET", key, today, "EX", "86400"])
    :ok
  end

  def clear do
    # Удалить все ключи с префиксом (для тестов)
    {:ok, keys} = Redix.command(:redix, ["KEYS", "#{@prefix}:*"])
    Enum.each(keys, fn key -> Redix.command(:redix, ["DEL", key]) end)
    :ok
  end
end
