defmodule LiveViewScheduler.Repo do
  use Ecto.Repo,
    otp_app: :live_view_scheduler,
    adapter: Ecto.Adapters.Postgres
end
