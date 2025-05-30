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
    attrs = Map.update(attrs, "headers", %{}, &decode_json/1)
    task
    |> cast(attrs, [:name, :schedule, :url, :method, :headers, :body, :status, :retry_count])
    |> validate_required([:name, :schedule, :url])
    |> put_default(:body, "")
    |> put_default(:headers, %{})
    |> put_default(:status, "active")
    |> put_default(:retry_count, 0)
    |> validate_inclusion(:method, ~w(GET POST PUT DELETE))
  end


  defp decode_json(""), do: %{}

  defp decode_json(str) when is_binary(str) do
    case Jason.decode(str) do
      {:ok, decoded} when is_map(decoded) -> decoded
      _ -> %{}
    end
  end

  defp decode_json(val), do: val

  defp put_default(changeset, field, default) do
    if Map.get(changeset.changes, field) == nil do
      put_change(changeset, field, default)
    else
      changeset
    end
  end

end
