defmodule Croniq.Redis.Pool do
  @moduledoc """
  Redis connection pool based on poolboy for asynchronous access to Redis via Redix.
  Use Croniq.Redis.Pool.command/1 to execute Redis commands with automatic connection management.
  """
  @pool_name :redix_pool

  def child_spec(_args) do
    :poolboy.child_spec(
      @pool_name,
      [
        name: {:local, @pool_name},
        worker_module: Redix,
        size: Application.get_env(:croniq, :redis_pool)[:pool_size],
        max_overflow: 0
      ],
      Application.get_env(:croniq, :redix)[:url]
    )
  end

  def command(command) do
    :poolboy.transaction(@pool_name, fn conn ->
      Redix.command(conn, command)
    end)
  end
end
