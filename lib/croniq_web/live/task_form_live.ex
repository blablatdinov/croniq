defmodule CroniqWeb.TaskFormLive do
  use CroniqWeb, :live_view
  alias Croniq.Task

  def mount(_params, _session, socket) do
    if socket.assigns.current_user.confirmed_at do
      headers_string = Jason.encode!(%{})
      changeset = Task.changeset(%Task{}, %{"headers" => headers_string, "task_type" => "recurring"})

      {:ok,
       assign(socket,
         changeset: changeset,
         task_type: "recurring",
         show_recurring_fields: true,
         show_delayed_fields: false
       )}
    else
      {:ok,
       socket
       |> put_flash(:error, "Please confirm your email address before creating tasks.")
       |> redirect(to: ~p"/tasks")}
    end
  end

  def handle_event("validate", %{"task" => task_params}, socket) do
    task_type = Map.get(task_params, "task_type", "recurring")

    changeset =
      %Task{}
      |> Task.changeset(task_params)
      |> Map.put(:action, :validate)

    {:noreply,
     assign(socket,
       changeset: changeset,
       task_type: task_type,
       show_recurring_fields: task_type == "recurring",
       show_delayed_fields: task_type == "delayed"
     )}
  end

  def handle_event("save", %{"task" => task_params}, socket) do
    case get_task_type(task_params) do
      "delayed" ->
        create_delayed_task(socket, task_params)
      _ ->
        create_recurring_task(socket, task_params)
    end
  end

  def handle_event("toggle_task_type", %{"task_type" => task_type}, socket) do
    IO.puts("Toggle task type to: #{task_type}")

    changeset =
      socket.assigns.changeset
      |> Ecto.Changeset.put_change(:task_type, task_type)
      |> Map.put(:action, :validate)

    show_recurring = task_type == "recurring"
    show_delayed = task_type == "delayed"

    IO.puts("show_recurring_fields: #{show_recurring}, show_delayed_fields: #{show_delayed}")

    {:noreply,
     assign(socket,
       changeset: changeset,
       task_type: task_type,
       show_recurring_fields: show_recurring,
       show_delayed_fields: show_delayed
     )}
  end

  defp get_task_type(%{"task_type" => task_type}), do: task_type
  defp get_task_type(%{"scheduled_at" => _}), do: "delayed"
  defp get_task_type(_), do: "recurring"

  defp create_delayed_task(socket, task_params) do
    case Croniq.Task.create_delayed_task(socket.assigns.current_user.id, task_params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Delayed task created successfully! Will execute at #{format_datetime(task.scheduled_at)}")
         |> push_navigate(to: ~p"/tasks/#{task.id}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp create_recurring_task(socket, task_params) do
    case Croniq.Task.create_task(socket.assigns.current_user.id, task_params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Recurring task created successfully!")
         |> push_navigate(to: ~p"/tasks/#{task.id}/edit")}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, changeset: changeset)}
    end
  end

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")
  end
end
