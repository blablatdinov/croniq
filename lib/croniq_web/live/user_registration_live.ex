defmodule CroniqWeb.UserRegistrationLive do
  use CroniqWeb, :live_view

  alias Croniq.Accounts
  alias Croniq.Accounts.User

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-sm">
      <.header class="text-center">
        Register for an account
        <:subtitle>
          Already registered?
          <.link navigate={~p"/users/log_in"} class="font-semibold text-brand hover:underline">
            Log in
          </.link>
          to your account now.
        </:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="registration_form"
        phx-submit="save"
        phx-change="validate"
        phx-trigger-action={@trigger_submit}
        action={~p"/users/log_in?_action=registered"}
        method="post"
      >
        <.error :if={@check_errors}>
          Oops, something went wrong! Please check the errors below.
        </.error>

        <.input field={@form[:email]} type="email" label="Email" required />
        <.input field={@form[:password]} type="password" label="Password" required />
        <input
          type="hidden"
          name="recaptcha_token"
          id="recaptcha_token"
          phx-hook="RecaptchaHook"
          data-sitekey={@site_key}
        />
        <%= if @show_v2 do %>
          <div id="recaptcha-wrapper" phx-hook="RecaptchaV2" data-sitekey={@site_v2_key}>
            <div class="g-recaptcha" data-sitekey={@site_v2_key}></div>
          </div>
        <% else %>
          <input type="hidden" name="recaptcha_token" id="recaptcha_token" phx-hook="RecaptchaHook" data-sitekey={@site_key} />
        <% end %>
        <:actions>
          <.button phx-disable-with="Creating account..." class="w-full">Create an account</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    changeset = Accounts.change_user_registration(%User{})

    socket =
      socket
      |> assign(
        trigger_submit: false,
        check_errors: false,
        site_key: Croniq.Recaptcha.site_key(),
        show_v2: false
      )
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("save", %{"user" => user_params} = params, socket) do
    token = Map.get(params, "recaptcha_token")
    version = :v3
    if Map.get(params, "g-recaptcha-response") do
      token = Map.get(params, "g-recaptcha-response")
      version = :v2
    end
    # recaptcha_v2_token = Map.get(params, "g-recaptcha-response") || Map.get(params, "recaptcha_token")
    # recaptcha_token = Map.get(params, "g-recaptcha-response") || Map.get(params, "recaptcha_token")
    IO.inspect({token, version})
    # IO.inspect(Map.get(params, "recaptcha_token"), label: "recaptcha_token")

    token_verified = Croniq.Recaptcha.verify_recaptcha(token, version)
    IO.inspect(token_verified, label: "token_verified")
    case token_verified do
      {:ok, _score} ->
        case Accounts.register_user(user_params) do
          {:ok, user} ->
            {:ok, _} =
              Accounts.deliver_user_confirmation_instructions(
                user,
                &url(~p"/users/confirm/#{&1}")
              )

            changeset = Accounts.change_user_registration(user)
            {:noreply, socket |> assign(trigger_submit: true) |> assign_form(changeset)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
        end

      {:low_score, score} ->
        IO.inspect(score, label: "low score")
        changeset =
          %User{}
          |> Accounts.change_user_registration(user_params)
          |> Ecto.Changeset.add_error(:base, "reCAPTCHA verification failed")

        {:noreply, socket |> assign(check_errors: true, show_v2: true, site_v2_key: Croniq.Recaptcha.site_v2_key()) |> assign_form(changeset)}

      {:error, reason} ->
        changeset =
          %User{}
          |> Accounts.change_user_registration(user_params)

        {:noreply, socket |> assign(check_errors: true) |> assign_form(changeset)}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Accounts.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
