defmodule Croniq.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :name, :string
    field :schedule, :string
    field :url, :string
    field :method, :string
    field :headers, :map
    field :body, :string
    field :status, :string
    field :retry_count, :integer

    timestamps()
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [:name, :schedule, :url, :method, :headers, :body, :status, :retry_count])
    |> validate_required([:name, :schedule, :url])
    |> validate_inclusion(:method, ~w(GET POST PUT DELETE))
  end
end
