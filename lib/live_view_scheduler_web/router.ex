defmodule LiveViewSchedulerWeb.Router do
  use LiveViewSchedulerWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {LiveViewSchedulerWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", LiveViewSchedulerWeb do
    pipe_through :browser

    get "/", PageController, :index

    live "/:interview_stage_id", InterviewAvailabilityLive.Index
  end
end
