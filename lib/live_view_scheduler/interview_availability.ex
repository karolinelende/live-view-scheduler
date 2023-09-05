defmodule LiveViewScheduler.InterviewAvailability do
  use Ecto.Schema
  import Ecto.Changeset
  alias LiveViewScheduler.InterviewStage
  alias Timex

  schema "interview_availability" do
    field :start_datetime, :utc_datetime_usec
    field :end_datetime, :utc_datetime_usec
    field :deleted, :boolean
    field :temp_id, :string, virtual: true
    field :date, :date, virtual: true
    field :overlaps, :boolean, virtual: true

    belongs_to :interview_stage, InterviewStage

    timestamps(type: :utc_datetime_usec)
  end

  def create_changeset(changeset \\ %__MODULE__{}, attrs) do
    changeset
    |> cast(attrs, [
      :start_datetime,
      :end_datetime,
      :interview_stage_id,
      :temp_id,
      :date,
      :deleted,
      :overlaps
    ])
    |> validate_required(:start_datetime, message: "Start time must be selected")
    |> validate_required(:end_datetime, message: "End time must be selected")
    |> foreign_key_constraint(:interview_stage_id,
      name: :interview_availability_interview_stage_id_fkey
    )
    |> validate_date_times()
    |> validate_cannot_delete_past_availability()
    |> validate_no_overlap()
  end

  defp validate_date_times(changeset = %{errors: []}) do
    start_datetime = get_change(changeset, :start_datetime)
    end_datetime = get_change(changeset, :end_datetime)

    duration =
      case get_field(changeset, :interview_stage) do
        nil -> nil
        %{duration: duration} -> duration
      end

    changeset
    |> validate_after(start_datetime, end_datetime)
    |> validate_same_day(start_datetime, end_datetime)
    |> validate_duration(start_datetime, end_datetime, duration)
  end

  defp validate_date_times(changeset), do: changeset

  defp validate_after(changeset, start_datetime, end_datetime)
       when is_nil(start_datetime) or is_nil(end_datetime),
       do: changeset

  defp validate_after(changeset, start_datetime, end_datetime) do
    if Timex.after?(start_datetime, end_datetime) do
      add_error(changeset, :start_datetime, "Start datetime cannot be after the end datetime")
    else
      changeset
    end
  end

  defp validate_same_day(changeset, start_datetime, end_datetime)
       when is_nil(start_datetime) or is_nil(end_datetime),
       do: changeset

  defp validate_same_day(changeset, start_datetime, end_datetime) do
    if Timex.shift(start_datetime, days: 1) |> DateTime.compare(end_datetime) == :gt do
      changeset
    else
      add_error(changeset, :end_datetime, "Cannot book multi day interview")
    end
  end

  defp validate_duration(changeset, start_datetime, end_datetime, duration)
       when is_nil(start_datetime) or is_nil(end_datetime) or is_nil(duration),
       do: changeset

  defp validate_duration(changeset, start_datetime, end_datetime, duration) do
    if Timex.before?(
         end_datetime,
         Timex.shift(start_datetime, minutes: duration)
       ) do
      add_error(
        changeset,
        :end_datetime,
        "End time must be at least #{duration} minutes after start time"
      )
    else
      changeset
    end
  end

  defp validate_cannot_delete_past_availability(changeset) do
    start_datetime = get_field(changeset, :start_datetime)

    if get_change(changeset, :deleted) &&
         DateTime.compare(start_datetime, DateTime.utc_now()) == :lt do
      add_error(changeset, :deleted, "Cannot delete availability in the past")
    else
      changeset
    end
  end

  defp validate_no_overlap(changeset) do
    if get_field(changeset, :overlaps) == true,
      do: add_error(changeset, :overlaps, "Cannot overlap with other availabilities"),
      else: changeset
  end
end
