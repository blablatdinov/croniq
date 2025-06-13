defmodule CroniqWeb.APIAuthJSON do

  def generate_token(%{token: token}) do
    %{"token" => token}
  end
end
