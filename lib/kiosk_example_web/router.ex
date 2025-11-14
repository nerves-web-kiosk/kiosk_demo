defmodule KioskExampleWeb.Router do
  use KioskExampleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {KioskExampleWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", KioskExampleWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/dashboard", DashboardLive
    live "/gpio", GPIOLive
  end

  # Other scopes may use custom stacks.
  # scope "/api", KioskExampleWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard for demonstration purposes
  #
  import Phoenix.LiveDashboard.Router

  scope "/dev" do
    pipe_through :browser

    live_dashboard "/dashboard", metrics: KioskExampleWeb.Telemetry
  end
end
