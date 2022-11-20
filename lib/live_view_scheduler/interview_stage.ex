defmodule LiveViewScheduler.InterviewStage do
  use Ecto.Schema
  alias LiveViewScheduler.InterviewAvailability

  schema "interview_stages" do
    field :name, :string
    field :duration, :integer

    has_many :interview_availabilities, InterviewAvailability,
      on_delete: :delete_all,
      on_replace: :mark_as_invalid

    timestamps(type: :utc_datetime_usec)
  end
end
