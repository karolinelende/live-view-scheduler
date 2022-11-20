defmodule LiveViewSchedulerWeb.PageController do
  use LiveViewSchedulerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
