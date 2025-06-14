defmodule Croniq.RequestLog do
  use Ecto.Schema
  import Ecto.Changeset

  schema "request_log" do
    belongs_to :task, Croniq.Task

    field :request, :string
    field :response, :string
    field :duration, :integer
    field :error, :string

    timestamps()
  end

  def changeset(rq_log, attrs) do
    rq_log
    |> cast(attrs, [:request, :response, :duration, :error])
    |> validate_required([:request, :duration])
  end
end
