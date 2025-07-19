# The MIT License (MIT).
#
# Copyright (c) 2025 Almaz Ilaletdinov <a.ilaletdinov@yandex.ru>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
# OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
# OR OTHER DEALINGS IN THE SOFTWARE.

defmodule Croniq.RequestLog do
  @moduledoc """
  Tracks execution history of scheduled tasks.

  Captures:
  - Full HTTP request/response data
  - Execution timing metrics
  - Error states and stack traces
  - Task execution context

  Provides audit trail and debugging capabilities
  for all automated requests.
  """
  use Ecto.Schema
  import Ecto.Changeset

  schema "request_log" do
    belongs_to :task, Croniq.Task

    field :request, :string
    field :response, :string
    field :duration, :integer
    field :error, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(rq_log, attrs) do
    rq_log
    |> cast(attrs, [:request, :response, :duration, :error, :task_id])
    |> validate_required([:request, :duration, :task_id])
  end

  def create_rq_log(attrs) do
    case %Croniq.RequestLog{} |> changeset(attrs) do
      %{valid?: false} = changeset ->
        {:error, changeset}

      changeset ->
        {:ok, Croniq.Repo.insert!(changeset)}
    end
  end
end
