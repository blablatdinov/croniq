defmodule Croniq.RequestsTest do
  use Croniq.DataCase, async: true
  import Mox

  alias Croniq.Requests
  alias Croniq.Task
  alias Croniq.RequestLog
  alias Croniq.Accounts.User

  setup :verify_on_exit!

  setup do
    user =
      %User{}
      |> User.registration_changeset(%{
        email: "test@example.com",
        password: "password123456"
      })
      |> Repo.insert!()

    task =
      Repo.insert!(%Task{
        user_id: user.id,
        name: "Test Task",
        schedule: "*/5 * * * *",
        url: "https://api.example.com/test",
        method: "POST",
        headers: %{"Content-Type" => "application/json", "Authorization" => "Basic token"},
        body: ~s({"key": "value"}),
        status: "active",
        retry_count: 0
      })

    {:ok, %{user: user, task: task}}
  end

  describe "send_request/1" do
    test "successfully sends HTTP request and logs the response", %{task: task} do
      expect(Croniq.HttpClientMock, :request, fn request ->
        assert request.method == "POST"
        assert request.url == "https://api.example.com/test"
        assert request.body == ~s({"key": "value"})
        assert length(request.headers) == 2
        assert {"Content-Type", "application/json"} in request.headers
        assert {"Authorization", "Basic token"} in request.headers

        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: ~s({"success": true}),
           headers: [{"Content-Type", "application/json"}]
         }}
      end)

      assert :ok = Requests.send_request(task.id)

      logs = Repo.all(RequestLog)
      assert length(logs) == 1

      log = List.first(logs)
      assert log.task_id == task.id
      assert log.duration >= 0
      assert is_nil(log.error)
      assert log.request =~ "POST /test HTTP/1.1"
      assert log.request =~ "HOST: api.example.com"
      assert log.request =~ "Content-Type: application/json"
      assert log.request =~ "Authorization: Basic token"
      assert log.request =~ ~s({"key": "value"})
      assert log.response =~ "HTTP/1.1 200 ok"
      assert log.response =~ ~s({"success": true})
    end

    test "handles HTTP request errors and logs them", %{task: task} do
      expect(Croniq.HttpClientMock, :request, fn request ->
        assert request.method == "POST"
        assert request.url == "https://api.example.com/test"
        assert request.body == ~s({"key": "value"})
        assert length(request.headers) == 2
        assert {"Content-Type", "application/json"} in request.headers
        assert {"Authorization", "Basic token"} in request.headers

        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      assert :ok = Requests.send_request(task.id)

      logs = Repo.all(RequestLog)
      assert length(logs) == 1

      log = List.first(logs)
      assert log.task_id == task.id
      assert log.duration >= 0
      assert log.error == "timeout"
      assert is_nil(log.response)
      assert log.request =~ "POST /test HTTP/1.1"
    end

    test "handles task with empty headers", %{user: user} do
      task_without_headers =
        Repo.insert!(%Task{
          user_id: user.id,
          name: "Task Without Headers",
          schedule: "*/5 * * * *",
          url: "https://api.example.com/test",
          method: "POST",
          headers: %{},
          body: ~s({"key": "value"}),
          status: "active",
          retry_count: 0
        })

      expect(Croniq.HttpClientMock, :request, fn request ->
        assert request.method == "POST"
        assert request.url == "https://api.example.com/test"
        assert request.body == ~s({"key": "value"})
        assert request.headers == []

        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "OK",
           headers: []
         }}
      end)

      assert :ok = Requests.send_request(task_without_headers.id)

      logs = Repo.all(RequestLog)
      log = List.first(logs)
      assert log.request =~ "POST /test HTTP/1.1"
      assert log.request =~ "HOST: api.example.com"
      refute log.request =~ "Content-Type:"
      refute log.request =~ "Authorization:"
    end

    test "handles task with empty request body", %{user: user} do
      task_without_body =
        Repo.insert!(%Task{
          user_id: user.id,
          name: "Task Without Body",
          schedule: "*/5 * * * *",
          url: "https://api.example.com/test",
          method: "POST",
          headers: %{"Content-Type" => "application/json", "Authorization" => "Basic token"},
          body: "",
          status: "active",
          retry_count: 0
        })

      expect(Croniq.HttpClientMock, :request, fn request ->
        assert request.method == "POST"
        assert request.url == "https://api.example.com/test"
        assert request.body == ""
        assert length(request.headers) == 2
        assert {"Content-Type", "application/json"} in request.headers
        assert {"Authorization", "Basic token"} in request.headers

        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "OK",
           headers: []
         }}
      end)

      assert :ok = Requests.send_request(task_without_body.id)

      logs = Repo.all(RequestLog)
      log = List.first(logs)
      assert log.request =~ "POST /test HTTP/1.1"
      refute log.request =~ ~s({"key": "value"})
    end

    test "correctly formats GET request", %{user: user} do
      get_task =
        Repo.insert!(%Task{
          user_id: user.id,
          name: "GET Task",
          schedule: "*/5 * * * *",
          url: "https://api.example.com/test",
          method: "GET",
          headers: %{"Content-Type" => "application/json", "Authorization" => "Basic token"},
          body: "",
          status: "active",
          retry_count: 0
        })

      expect(Croniq.HttpClientMock, :request, fn request ->
        assert request.method == "GET"
        assert request.url == "https://api.example.com/test"
        assert request.body == ""
        assert length(request.headers) == 2
        assert {"Content-Type", "application/json"} in request.headers
        assert {"Authorization", "Basic token"} in request.headers

        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "OK",
           headers: []
         }}
      end)

      assert :ok = Requests.send_request(get_task.id)

      logs = Repo.all(RequestLog)
      log = List.first(logs)
      assert log.request =~ "GET /test HTTP/1.1"
      assert log.request =~ "HOST: api.example.com"
    end

    test "correctly formats response with different status codes", %{task: task} do
      expect(Croniq.HttpClientMock, :request, fn request ->
        assert request.method == "POST"
        assert request.url == "https://api.example.com/test"
        assert request.body == ~s({"key": "value"})
        assert length(request.headers) == 2
        assert {"Content-Type", "application/json"} in request.headers
        assert {"Authorization", "Basic token"} in request.headers

        {:ok,
         %HTTPoison.Response{
           status_code: 404,
           body: ~s({"error": "Not Found"}),
           headers: [{"Content-Type", "application/json"}]
         }}
      end)

      assert :ok = Requests.send_request(task.id)

      logs = Repo.all(RequestLog)
      log = List.first(logs)
      assert log.response =~ "HTTP/1.1 404 not_found"
      assert log.response =~ ~s({"error": "Not Found"})
    end

    test "handles different HTTPoison error types", %{task: task} do
      errors = [
        %HTTPoison.Error{reason: :timeout},
        %HTTPoison.Error{reason: :econnrefused},
        %HTTPoison.Error{reason: :nxdomain},
        %HTTPoison.Error{reason: :closed}
      ]

      Enum.each(errors, fn error ->
        expect(Croniq.HttpClientMock, :request, fn request ->
          assert request.method == "POST"
          assert request.url == "https://api.example.com/test"
          assert request.body == ~s({"key": "value"})
          assert length(request.headers) == 2
          assert {"Content-Type", "application/json"} in request.headers
          assert {"Authorization", "Basic token"} in request.headers

          {:error, error}
        end)

        assert :ok = Requests.send_request(task.id)

        logs = Repo.all(RequestLog)
        log = List.last(logs)
        assert log.error == to_string(error.reason)
        assert is_nil(log.response)
      end)
    end

    test "handles gzip response and logs compressed body", %{task: task} do
      original_body = ~s({"gzipped": true})
      gzipped_body = :zlib.gzip(original_body)

      expect(Croniq.HttpClientMock, :request, fn request ->
        assert request.method == "POST"
        assert request.url == "https://api.example.com/test"
        assert request.body == ~s({"key": "value"})
        assert length(request.headers) == 2
        assert {"Content-Type", "application/json"} in request.headers
        assert {"Authorization", "Basic token"} in request.headers

        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: gzipped_body,
           headers: [
             {"Content-Type", "application/json"},
             {"Content-Encoding", "gzip"}
           ]
         }}
      end)

      assert :ok = Requests.send_request(task.id)

      logs = Repo.all(RequestLog)
      assert length(logs) == 1
      log = List.first(logs)
      assert log.response =~ "HTTP/1.1 200 ok"
      assert log.response =~ "Content-Encoding: gzip"

      assert log.response =~ original_body
    end

    test "does not allow more than 100 requests per day across all user's tasks", %{
      user: user,
      task: task
    } do
      task2 =
        Repo.insert!(%Task{
          user_id: user.id,
          name: "Second Task",
          schedule: "*/5 * * * *",
          url: "https://api.example.com/second",
          method: "POST",
          headers: %{},
          body: "",
          status: "active",
          retry_count: 0
        })

      now = DateTime.utc_now()
      midnight = %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}

      for _ <- 1..50 do
        Repo.insert!(%RequestLog{
          task_id: task.id,
          request: "req",
          response: "resp",
          duration: 1,
          error: nil,
          inserted_at: DateTime.add(midnight, 1, :second),
          updated_at: DateTime.add(midnight, 1, :second)
        })

        Repo.insert!(%RequestLog{
          task_id: task2.id,
          request: "req",
          response: "resp",
          duration: 1,
          error: nil,
          inserted_at: DateTime.add(midnight, 2, :second),
          updated_at: DateTime.add(midnight, 2, :second)
        })
      end

      refute_receive {:http_client_called, _}, 10
      assert :error = Requests.send_request(task.id)
      assert :error = Requests.send_request(task2.id)
    end

    test "allows the 100th request but not the 101st across all user's tasks", %{
      user: user,
      task: task
    } do
      task2 =
        Repo.insert!(%Task{
          user_id: user.id,
          name: "Second Task",
          schedule: "*/5 * * * *",
          url: "https://api.example.com/second",
          method: "POST",
          headers: %{},
          body: "",
          status: "active",
          retry_count: 0
        })

      now = DateTime.utc_now()
      midnight = %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}

      for _ <- 1..60 do
        Repo.insert!(%RequestLog{
          task_id: task.id,
          request: "req",
          response: "resp",
          duration: 1,
          error: nil,
          inserted_at: DateTime.add(midnight, 1, :second),
          updated_at: DateTime.add(midnight, 1, :second)
        })
      end

      for _ <- 1..39 do
        Repo.insert!(%RequestLog{
          task_id: task2.id,
          request: "req",
          response: "resp",
          duration: 1,
          error: nil,
          inserted_at: DateTime.add(midnight, 2, :second),
          updated_at: DateTime.add(midnight, 2, :second)
        })
      end

      expect(Croniq.HttpClientMock, :request, 1, fn _ ->
        send(self(), {:http_client_called, :ok})
        {:ok, %HTTPoison.Response{status_code: 200, body: "ok", headers: []}}
      end)

      assert :ok = Requests.send_request(task.id)
      assert_received {:http_client_called, :ok}

      refute_receive {:http_client_called, _}, 10
      assert :error = Requests.send_request(task.id)
      assert :error = Requests.send_request(task2.id)
    end

    test "does not count requests from previous days for all user's tasks", %{
      user: user,
      task: task
    } do
      task2 =
        Repo.insert!(%Task{
          user_id: user.id,
          name: "Second Task",
          schedule: "*/5 * * * *",
          url: "https://api.example.com/second",
          method: "POST",
          headers: %{},
          body: "",
          status: "active",
          retry_count: 0
        })

      now = DateTime.utc_now()
      midnight = %{now | hour: 0, minute: 0, second: 0, microsecond: {0, 0}}
      yesterday = DateTime.add(midnight, -60 * 60 * 24, :second)

      for _ <- 1..75 do
        Repo.insert!(%RequestLog{
          task_id: task.id,
          request: "req",
          response: "resp",
          duration: 1,
          error: nil,
          inserted_at: yesterday,
          updated_at: yesterday
        })

        Repo.insert!(%RequestLog{
          task_id: task2.id,
          request: "req",
          response: "resp",
          duration: 1,
          error: nil,
          inserted_at: yesterday,
          updated_at: yesterday
        })
      end

      expect(Croniq.HttpClientMock, :request, 2, fn _ ->
        send(self(), {:http_client_called, :ok})
        {:ok, %HTTPoison.Response{status_code: 200, body: "ok", headers: []}}
      end)

      assert :ok = Requests.send_request(task.id)
      assert_received {:http_client_called, :ok}
      assert :ok = Requests.send_request(task2.id)
      assert_received {:http_client_called, :ok}
    end

    test "does not send request if task is disabled", %{user: user} do
      task =
        Repo.insert!(%Task{
          user_id: user.id,
          name: "Disabled Task",
          schedule: "* * * * *",
          url: "https://example.com",
          method: "POST",
          headers: %{},
          body: "",
          status: "disabled",
          retry_count: 0
        })

      assert :ok = Requests.send_request(task.id)
    end
  end

  describe "limit notification and ETS" do
    setup %{user: user, task: task} do
      Croniq.LimitNotification.clear()
      {:ok, %{user: user, task: task}}
    end

    test "sends email notification on first limit exceed", %{user: user, task: task} do
      import Swoosh.TestAssertions
      # Fill the log up to the limit
      request_limit = Application.get_env(:croniq, :request_limit_per_day)

      for _ <- 1..request_limit do
        Repo.insert!(%RequestLog{
          task_id: task.id,
          request: "req",
          response: "resp",
          duration: 1,
          error: nil,
          inserted_at: DateTime.truncate(DateTime.utc_now(), :second),
          updated_at: DateTime.truncate(DateTime.utc_now(), :second)
        })
      end

      Requests.send_request(task.id)
      # :timer.sleep(20)
      assert_email_sent(fn email ->
        email.subject =~ "Request Limit Exceeded" and
          Enum.any?(email.to, fn {_name, addr} -> addr == user.email end)
      end)
    end

    test "does not send email twice in the same day", %{task: task} do
      import Swoosh.TestAssertions
      request_limit = Application.get_env(:croniq, :request_limit_per_day)

      for _ <- 1..request_limit do
        Repo.insert!(%RequestLog{
          task_id: task.id,
          request: "req",
          response: "resp",
          duration: 1,
          error: nil,
          inserted_at: DateTime.truncate(DateTime.utc_now(), :second),
          updated_at: DateTime.truncate(DateTime.utc_now(), :second)
        })
      end

      Requests.send_request(task.id)
      assert_email_sent()
      Requests.send_request(task.id)
      refute_receive {:email, _}, 50
    end
  end

  describe "private functions" do
    test "format_request correctly formats HTTP request" do
      request = %HTTPoison.Request{
        method: :POST,
        url: "https://api.example.com/path/to/resource",
        body: ~s({"data": "value"}),
        headers: [{"Content-Type", "application/json"}, {"Authorization", "Basic token"}]
      }

      formatted = Requests.format_request(request)

      assert formatted =~ "POST /path/to/resource HTTP/1.1"
      assert formatted =~ "HOST: api.example.com"
      assert formatted =~ "Content-Type: application/json"
      assert formatted =~ "Authorization: Basic token"
      assert formatted =~ ~s({"data": "value"})
    end

    test "format_response correctly formats HTTP response" do
      response = %HTTPoison.Response{
        status_code: 201,
        body: ~s({"id": 123, "status": "created"}),
        headers: [{"Content-Type", "application/json"}, {"Location", "/api/resource/123"}]
      }

      formatted = Requests.format_response(response)

      assert formatted =~ "HTTP/1.1 201 created"
      assert formatted =~ "Content-Type: application/json"
      assert formatted =~ "Location: /api/resource/123"
      assert formatted =~ ~s({"id": 123, "status": "created"})
    end

    test "headers_str correctly formats headers" do
      headers = [{"Content-Type", "application/json"}, {"Authorization", "Basic token"}]
      formatted = Requests.headers_str(headers)

      assert formatted =~ "Content-Type: application/json"
      assert formatted =~ "Authorization: Basic token"
      assert String.contains?(formatted, "\r\n")
    end
  end
end
