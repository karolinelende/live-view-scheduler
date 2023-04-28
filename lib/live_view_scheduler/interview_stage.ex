defmodule LiveViewScheduler.InterviewStage do
  use Ecto.Schema
  import Ecto.Changeset
  alias LiveViewScheduler.InterviewAvailability

  schema "interview_stages" do
    field :name, :string
    field :duration, :integer

    has_many :interview_availabilities, InterviewAvailability,
      on_delete: :delete_all,
      on_replace: :mark_as_invalid

    timestamps(type: :utc_datetime_usec)
  end

  def availability_changeset(
        %__MODULE__{interview_availabilities: interview_availabilities} = interview_stage,
        attrs
      )
      when is_list(interview_availabilities) do
    interview_stage
    |> cast(attrs, [])
    |> cast_assoc(
      :interview_availabilities,
      with: fn interview_availability, attributes ->
        %{interview_availability | interview_stage: interview_stage}
        |> InterviewAvailability.create_changeset(attributes)
      end
    )
  end
end
