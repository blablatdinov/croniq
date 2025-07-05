defmodule Croniq.Accounts.UserNotifier do
  @moduledoc """
  Handles transactional email delivery.

  Templates include:
  - Account confirmation instructions
  - Password reset workflows
  - Email change verification
  - Security notifications

  Uses Swoosh for email composition and delivery,
  with plain-text templates for reliability.
  """
  import Swoosh.Email

  alias Croniq.Mailer

  # Delivers the email using the application mailer.
  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Croniq", "dev@croniq.ilaletdinov.ru"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to confirm account.
  """
  def deliver_confirmation_instructions(user, url) do
    deliver(user.email, "Account Confirmation - Croniq", """

    ==============================

    Hello!

    Thank you for registering with Croniq! To complete your registration and activate your account, please click the link below:

    #{url}

    If you didn't create an account with Croniq, please ignore this email.

    This link is valid for 7 days.

    Best regards,
    The Croniq Team

    ==============================
    """)
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Password Reset - Croniq", """

    ==============================

    Hello!

    You requested a password reset for your Croniq account. To create a new password, please click the link below:

    #{url}

    If you didn't request a password reset, please ignore this email.

    This link is valid for 24 hours.

    Best regards,
    The Croniq Team

    ==============================
    """)
  end

  @doc """
  Deliver instructions to update a user email.
  """
  def deliver_update_email_instructions(user, url) do
    deliver(user.email, "Email Change - Croniq", """

    ==============================

    Hello!

    You requested to change the email address for your Croniq account. To confirm this change, please click the link below:

    #{url}

    If you didn't request an email change, please ignore this email.

    This link is valid for 7 days.

    Best regards,
    The Croniq Team

    ==============================
    """)
  end

  @doc """
  Sends an email to the user about exceeding the request limit.
  """
  def deliver_limit_exceeded_notification(user) do
    import Swoosh.Email
    request_limit = Application.get_env(:croniq, :request_limit_per_day)

    email =
      new()
      |> to(user.email)
      |> from({"Croniq", "dev@croniq.ilaletdinov.ru"})
      |> subject("Request Limit Exceeded - Croniq")
      |> text_body("""

      ==============================

      Hello!

      You have exceeded your daily request limit (#{request_limit} per day) in Croniq. New requests will not be processed until the next day.

      If you need a higher limit, please contact support.

      Best regards,
      The Croniq Team

      ==============================
      """)

    Croniq.Mailer.deliver(email)
  end
end
