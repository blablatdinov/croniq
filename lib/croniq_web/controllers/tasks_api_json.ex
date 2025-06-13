defmodule CroniqWeb.TasksAPIJSON do
  def list(%{tasks: tasks}) do
    %{"results" => tasks}
  end

  def detail(%{task: task}) do
    task
  end
end
