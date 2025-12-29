# SPDX-FileCopyrightText: Copyright (c) 2025-2026 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
# SPDX-License-Identifier: MIT

defmodule CroniqWeb.TasksAPIJSON do
  def list(%{tasks: tasks}) do
    %{"results" => tasks}
  end

  def detail(%{task: task}) do
    task
  end
end
