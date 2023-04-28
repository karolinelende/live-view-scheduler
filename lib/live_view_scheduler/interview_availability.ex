defmodule LiveViewScheduler.InterviewAvailability do
  use Ecto.Schema
  alias LiveViewScheduler.InterviewStage
  alias Timex

  schema "interview_availability" do
    field :start_datetime, :utc_datetime_usec
    field :end_datetime, :utc_datetime_usec
    field :deleted, :boolean
    field :temp_id, :string, virtual: true
    field :date, :date, virtual: true

    belongs_to :interview_stage, InterviewStage

    timestamps(type: :utc_datetime_usec)
  end
end
