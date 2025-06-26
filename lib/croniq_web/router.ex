defmodule CroniqWeb.Router do
  use CroniqWeb, :router
  # import Phoenix.Controller, only: [action_fallback: 1]

  import CroniqWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {CroniqWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    # action_fallback CroniqWeb.FallbackController
  end

  pipeline :api_guard do
    plug :fetch_api_user
  end

  scope "/", CroniqWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/docs", PageController, :docs
  end

  scope "/tasks", CroniqWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/", TasksController, :tasks
    post "/", TasksController, :create
    get "/new", TasksController, :new_task
    get "/:task_id/edit", TasksController, :edit_form
    get "/:task_id", TasksController, :task_details
    put "/:task_id", TasksController, :edit
    # TODO: make post
    delete "/:task_id", TasksController, :delete
    get "/:task_id/requests-log", TasksController, :requests_log
    get "/:task_id/requests-log/:rq_log_id", TasksController, :request_log_detail
  end

  scope "/api/v1/auth", CroniqWeb do
    pipe_through [:api]

    post "/", APIAuthController, :generate_token
  end

  scope "/api/v1/tasks", CroniqWeb do
    pipe_through [:api, :api_guard]

    get "/", TasksAPIController, :list
    post "/", TasksAPIController, :create
    get "/:task_id", TasksAPIController, :detail
    put "/:task_id", TasksAPIController, :edit
    delete "/:task_id", TasksAPIController, :delete
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:croniq, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: CroniqWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", CroniqWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{CroniqWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      get "/users/register", AccountsController, :registration_form
      post "/users/register", AccountsController, :registration
      get "/users/log_in", AccountsController, :log_in_form
      post "/users/log_in", AccountsController, :log_in
    end
  end

  scope "/", CroniqWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{CroniqWeb.UserAuth, :ensure_authenticated}] do
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email
    end
  end

  scope "/", CroniqWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{CroniqWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end
end
