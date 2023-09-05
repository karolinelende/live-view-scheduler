defmodule LiveViewScheduler.InterviewStages do
  import Ecto.Query
  alias LiveViewScheduler.Repo
  alias LiveViewScheduler.InterviewStage

  def create_interview_stage(attrs \\ %{}) do
    %InterviewStage{}
    |> InterviewStage.create_changeset(attrs)
    |> Repo.insert()
  end

  def get_by_id!(id) do
    from(is in InterviewStage, where: is.id == ^id)
    |> Repo.one!()
  end

  def get_weeks_availability_for_stage(interview_stage_id, start_of_week = %Date{}) do
    get_weeks_availability_for_stage(
      interview_stage_id,
      start_of_week |> DateTime.new!(~T|00:00:00|)
    )
  end

  def get_weeks_availability_for_stage(interview_stage_id, start_of_week) do
    end_of_week = Timex.shift(start_of_week, weeks: 1)

    Repo.one(
      from is in InterviewStage,
        left_join: ia in assoc(is, :interview_availabilities),
        on:
          not ia.deleted and
            ia.start_datetime >= ^start_of_week and
            ia.start_datetime < ^end_of_week,
        where: is.id == ^interview_stage_id,
        preload: [interview_availabilities: ia],
        order_by: ia.start_datetime
    )
    |> Map.update!(:interview_availabilities, fn availabilities ->
      availabilities |> Enum.map(&%{&1 | date: DateTime.to_date(&1.start_datetime)})
    end)
  end
end
