defmodule Croniq.LimitNotification do
  @moduledoc """
  In-memory (ETS) storage for tracking when a user was last notified about exceeding the request limit.
  Used to prevent sending multiple emails per day to the same user.
  Data is lost on application restart.
  """
  @table :limit_notification_sent

  def start_link do
    :ets.new(@table, [:named_table, :public, :set, {:read_concurrency, true}])
    {:ok, self()}
  rescue
    ArgumentError -> {:ok, self()}
  end

  def notified_today?(user_id) do
    case :ets.lookup(@table, user_id) do
      [{^user_id, date}] -> date == Date.utc_today()
      _ -> false
    end
  end

  def mark_notified(user_id) do
    :ets.insert(@table, {user_id, Date.utc_today()})
    :ok
  end
end
