defmodule Croniq.RequestsTest do
  use Croniq.DataCase, async: true
  import Mox

  alias Croniq.Requests
  alias Croniq.Task
  alias Croniq.RequestLog
  alias Croniq.Accounts.User

  setup :verify_on_exit!

  describe "send_request/1" do
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

    test "успешно выполняет HTTP запрос и логирует ответ", %{task: task} do
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

    test "обрабатывает ошибку HTTP запроса и логирует её", %{task: task} do
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

    test "обрабатывает задачу с пустыми заголовками", %{user: user} do
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

    test "обрабатывает задачу с пустым телом запроса", %{user: user} do
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

      # Выполняем тест
      assert :ok = Requests.send_request(task_without_body.id)

      # Проверяем результат
      logs = Repo.all(RequestLog)
      log = List.first(logs)
      assert log.request =~ "POST /test HTTP/1.1"
      # Проверяем, что тело запроса пустое
      refute log.request =~ ~s({"key": "value"})
    end

    test "правильно форматирует GET запрос", %{user: user} do
      get_task =
        Repo.insert!(%Task{
          user_id: user.id,
          name: "GET Task",
          schedule: "*/5 * * * *",
          url: "https://api.example.com/test",
          method: "GET",
          headers: %{"Content-Type" => "application/json", "Authorization" => "Basic token"},
          # Используем пустую строку вместо nil
          body: "",
          status: "active",
          retry_count: 0
        })

      # Мокируем HTTPoison.request для успешного ответа
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

      # Выполняем тест
      assert :ok = Requests.send_request(get_task.id)

      # Проверяем результат
      logs = Repo.all(RequestLog)
      log = List.first(logs)
      assert log.request =~ "GET /test HTTP/1.1"
      assert log.request =~ "HOST: api.example.com"
    end

    test "правильно форматирует ответ с различными статус кодами", %{task: task} do
      # Мокируем HTTPoison.request для ответа с 404 статусом
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

      # Выполняем тест
      assert :ok = Requests.send_request(task.id)

      # Проверяем результат
      logs = Repo.all(RequestLog)
      log = List.first(logs)
      assert log.response =~ "HTTP/1.1 404 not_found"
      assert log.response =~ ~s({"error": "Not Found"})
    end

    test "обрабатывает различные типы ошибок HTTPoison", %{task: task} do
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

        # Выполняем тест
        assert :ok = Requests.send_request(task.id)

        # Проверяем результат
        logs = Repo.all(RequestLog)
        log = List.last(logs)
        assert log.error == to_string(error.reason)
        assert is_nil(log.response)
      end)
    end

    test "обрабатывает gzip-ответ и логирует сжатое тело", %{task: task} do
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

      # Проверяем, что в логах хранится уже распакованный текст
      assert log.response =~ original_body
    end
  end

  describe "private functions" do
    test "format_request правильно форматирует HTTP запрос" do
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

    test "format_response правильно форматирует HTTP ответ" do
      response = %HTTPoison.Response{
        status_code: 201,
        body: ~s({"id": 123, "status": "created"}),
        headers: [{"Content-Type", "application/json"}, {"Location", "/api/resource/123"}]
      }

      formatted = Requests.format_response(response)

      # Исправляем регистр
      assert formatted =~ "HTTP/1.1 201 created"
      assert formatted =~ "Content-Type: application/json"
      assert formatted =~ "Location: /api/resource/123"
      assert formatted =~ ~s({"id": 123, "status": "created"})
    end

    test "headers_str правильно форматирует заголовки" do
      headers = [{"Content-Type", "application/json"}, {"Authorization", "Basic token"}]
      formatted = Requests.headers_str(headers)

      assert formatted =~ "Content-Type: application/json"
      assert formatted =~ "Authorization: Basic token"
      assert String.contains?(formatted, "\r\n")
    end
  end
end
