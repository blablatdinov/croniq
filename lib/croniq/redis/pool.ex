# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

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
    start_time = System.monotonic_time(:millisecond)
    command_name = List.first(command) |> to_string() |> String.downcase() |> String.to_atom()

    result = :poolboy.transaction(@pool_name, fn conn ->
      Redix.command(conn, command)
    end)

    duration = System.monotonic_time(:millisecond) - start_time

    case result do
      {:ok, _} ->
        :telemetry.execute(
          [:croniq, :redis, :command],
          %{duration: duration},
          %{command: command_name}
        )

      {:error, error} ->
        error_type =
          case error do
            %{__struct__: struct} when is_atom(struct) ->
              struct
              |> Module.split()
              |> List.last()
              |> String.to_atom()

            _ ->
              :unknown_error
          end

        :telemetry.execute(
          [:croniq, :redis, :error],
          %{count: 1},
          %{error_type: error_type}
        )
    end

    # Emit pool metrics
    pool_size = :poolboy.info(@pool_name, :size)
    pool_workers = :poolboy.info(@pool_name, :workers)
    available_workers = length(pool_workers)

    :telemetry.execute(
      [:croniq, :redis, :pool, :available_workers],
      %{count: available_workers},
      %{}
    )

    result
  end
end
