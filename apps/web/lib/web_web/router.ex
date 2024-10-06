defmodule WebWeb.Router do
  use WebWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:fetch_live_flash)
    plug(:put_root_layout, html: {WebWeb.Layouts, :root})
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :event_stream do
    plug(:accepts, ["event-stream"])
  end

  scope "/", WebWeb do
    pipe_through(:browser)

    get("/", PageController, :home)
    get("/thumbnail", ThumbnailController, :serve_thumbnail)
  end

  scope "/api", WebWeb do
    pipe_through(:api)
    post("/pipeline/scan", PipelineController, :scan)
    post("/pipeline/generate-pdf", PipelineController, :generate_pdf)
    delete("/pages/:filename", PipelineController, :delete_page)
  end

  scope "/api", WebWeb do
    pipe_through(:event_stream)
    get("/console/status_stream", ConsoleController, :status_stream)
    get("/thumbnails/stream", ThumbnailController, :thumbnail_stream)
  end

  # Other scopes may use custom stacks.
  # scope "/api", WebWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:web, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway)curl -N http://localhost:4000/stream_status.
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through(:browser)

      live_dashboard("/dashboard", metrics: WebWeb.Telemetry)
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
