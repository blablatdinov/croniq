defmodule CroniqWeb.FallbackController do
  use CroniqWeb, :controller
  use CroniqWeb, :controller

  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(json: CroniqWeb.ErrorJSON)
    |> render(:errors, changeset: changeset)
  end
end
