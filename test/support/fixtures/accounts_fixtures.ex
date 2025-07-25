defmodule Croniq.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Croniq.Accounts` context.
  """

  def unique_user_email, do: "user#{System.unique_integer()}@example.com"
  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password()
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Croniq.Accounts.register_user()

    user
  end

  def admin_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Croniq.Accounts.register_admin()

    user
  end

  def confirmed_user_fixture(attrs \\ %{}) do
    user = user_fixture(attrs)

    {:ok, confirmed_user} =
      user
      |> Croniq.Accounts.User.confirm_changeset()
      |> Croniq.Repo.update()

    confirmed_user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
