defmodule Croniq.LimitNotification do
  use GenServer
  @table :limit_notification_sent

  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init(_) do
    :ets.new(@table, [:named_table, :public, :set, {:read_concurrency, true}])
    {:ok, %{}}
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

  def clear do
    :ets.delete_all_objects(@table)
  end
end
