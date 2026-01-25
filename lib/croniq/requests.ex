# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule Croniq.Requests do
  @moduledoc """
  Executes and logs HTTP requests for scheduled tasks.

  Features:
  - Makes HTTP calls with configurable methods/headers/bodies
  - Tracks response metrics and duration
  - Stores detailed request/response logs
  - Handles errors with retry logic
  - Formats raw HTTP traffic for debugging

  Integrates with Task model to provide end-to-end execution tracking.
  """
  alias Croniq.Repo
  alias Croniq.Task
  require Logger
  import Ecto.Query

  def send_request(task_id) when is_integer(task_id) do
    case Repo.get_by(Task, id: task_id, status: "active") do
      nil ->
        Logger.error("Task #{task_id} is not active")
        :ok

      task ->
        send_request(task)
    end
  end

  def send_request(task) do
    start_time = System.monotonic_time(:millisecond)

    now = DateTime.utc_now()
    midnight = %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}

    user_id = task.user_id

    user_task_ids =
      Task
      |> where([t], t.user_id == ^user_id)
      |> select([t], t.id)
      |> Repo.all()

    count =
      Croniq.RequestLog
      |> where([r], r.task_id in ^user_task_ids and r.inserted_at > ^midnight)
      |> select([r], count(r.id))
      |> Repo.one()

    request_limit = Application.get_env(:croniq, :request_limit_per_day)

    # Emit usage metric
    user_id_str = Integer.to_string(user_id)

    :telemetry.execute(
      [:croniq, :limits, :usage, :requests_today],
      %{count: count},
      %{user_id: user_id_str}
    )

    if count >= request_limit do
      Logger.error("Request limit (#{request_limit} per day) exceeded for user #{user_id}")

      # Emit limit exceeded metric
      user_id_str = Integer.to_string(user_id)

      :telemetry.execute(
        [:croniq, :limits, :exceeded],
        %{count: 1},
        %{user_id: user_id_str}
      )

      user = Croniq.Accounts.get_user!(user_id)

      unless Croniq.LimitNotification.notified_today?(user_id) do
        Croniq.Accounts.UserNotifier.deliver_limit_exceeded_notification(user)
        Croniq.LimitNotification.mark_notified(user_id)

        # Emit notification sent metric
        user_id_str = Integer.to_string(user_id)

        :telemetry.execute(
          [:croniq, :limits, :notifications, :sent],
          %{count: 1},
          %{user_id: user_id_str}
        )
      end

      :error
    else
      request = %HTTPoison.Request{
        method: task.method,
        url: task.url,
        body: task.body,
        headers: Enum.map(task.headers, fn {key, value} -> {to_string(key), to_string(value)} end)
      }

      http_client = Application.get_env(:croniq, :http_client, Croniq.HttpClient.HTTPoison)

      Logger.info("Sending request for task: #{task.id}")

      request_size = if request.body, do: byte_size(request.body), else: 0

      case http_client.request(request) do
        {:ok, response} ->
          Logger.info(
            Enum.join(
              [
                "Request for task #{task.id} completed, status_code=#{response.status_code}",
                "response_body=#{response.body}",
                "response_headers=#{headers_str(response.headers)}"
              ],
              " "
            )
          )

          duration = System.monotonic_time(:millisecond) - start_time
          response_size = if response.body, do: byte_size(response.body), else: 0
          status_code = response.status_code

          # Emit success metrics
          task_id_str = Integer.to_string(task.id)
          method_atom = String.to_atom(String.downcase(task.method))

          :telemetry.execute(
            [:croniq, :request, :success],
            %{duration: duration, count: 1},
            %{task_id: task_id_str, method: method_atom, status_code: status_code}
          )

          :telemetry.execute(
            [:croniq, :request, :status_code],
            %{count: 1},
            %{status_code: status_code, task_id: task_id_str}
          )

          :telemetry.execute(
            [:croniq, :request, :duration],
            %{duration: duration},
            %{task_id: task_id_str, method: method_atom, status_code: status_code}
          )

          :telemetry.execute(
            [:croniq, :request, :request_size],
            %{request_size: request_size},
            %{task_id: task_id_str}
          )

          :telemetry.execute(
            [:croniq, :request, :response_size],
            %{response_size: response_size},
            %{task_id: task_id_str, status_code: status_code}
          )

          # Emit client/server error metrics
          cond do
            status_code >= 400 and status_code < 500 ->
              :telemetry.execute(
                [:croniq, :request, :client_error],
                %{count: 1},
                %{status_code: status_code}
              )

            status_code >= 500 ->
              :telemetry.execute(
                [:croniq, :request, :server_error],
                %{count: 1},
                %{status_code: status_code}
              )

            true ->
              :ok
          end

          log_successful_response(request, response, duration, task)

        {:error, error} ->
          Logger.error("Request for task #{task.id} failed, error=#{inspect(error)}")

          duration = System.monotonic_time(:millisecond) - start_time

          # Extract error type safely
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

          # Check if it's a timeout
          is_timeout = case error do
            %HTTPoison.Error{reason: :timeout} -> true
            %HTTPoison.Error{reason: {:timeout, _}} -> true
            _ -> false
          end

          # Emit error metrics
          task_id_str = Integer.to_string(task.id)

          :telemetry.execute(
            [:croniq, :request, :error],
            %{duration: duration, count: 1},
            %{task_id: task_id_str, error_type: error_type}
          )

          if is_timeout do
            :telemetry.execute(
              [:croniq, :request, :timeout],
              %{count: 1},
              %{task_id: task_id_str}
            )
          end

          log_failed_response(request, error, duration, task)
      end

      :ok
    end
  end

  def log_successful_response(request, response, duration, task) do
    %Croniq.RequestLog{}
    |> Croniq.RequestLog.changeset(%{
      request: format_request(request),
      response: format_response(response),
      duration: duration,
      error: nil,
      task_id: task.id
    })
    |> Repo.insert!()
  end

  def log_failed_response(request, error, duration, task) do
    %Croniq.RequestLog{}
    |> Croniq.RequestLog.changeset(%{
      request: format_request(request),
      response: nil,
      duration: duration,
      error: to_string(error.reason),
      task_id: task.id
    })
    |> Repo.insert!()
  end

  def format_request(request) do
    """
    #{request.method} #{URI.parse(request.url).path} HTTP/1.1
    HOST: #{URI.parse(request.url).host}
    #{headers_str(request.headers)}

    #{request.body || ""}
    """
    |> String.trim()
  end

  def format_response(response) do
    body =
      case Enum.find(response.headers, fn {k, v} ->
             String.downcase(k) == "content-encoding" and String.downcase(v) == "gzip"
           end) do
        nil ->
          response.body || ""

        _ ->
          try do
            decompressed = :zlib.gunzip(response.body)
            if is_binary(decompressed), do: decompressed, else: response.body || ""
          rescue
            _ -> response.body || ""
          end
      end

    """
    HTTP/1.1 #{response.status_code} #{Plug.Conn.Status.reason_atom(response.status_code)}
    #{headers_str(response.headers)}

    #{body}
    """
    |> String.trim()
  end

  def headers_str(headers) do
    Enum.map_join(
      headers,
      "\r\n",
      fn {k, v} -> "#{k}: #{v}" end
    )
  end
end
