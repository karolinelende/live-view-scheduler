defmodule LiveViewSchedulerWeb.InterviewAvailabilityLive.Index do
  use Phoenix.LiveView
  alias LiveViewSchedulerWeb.InterviewAvailabilityLive.FormComponents
  alias LiveViewScheduler.{InterviewStage, InterviewStages}

  def mount(%{"interview_stage_id" => interview_stage_id}, _session, socket) do
    socket =
      load_then_assign_interview_stage_and_changeset(
        socket,
        interview_stage_id,
        Timex.beginning_of_week(Date.utc_today())
      )
      |> assign(edit_mode: false)

    {:ok, socket}
  end

  def handle_event("toggle-edit-mode", _, socket) do
    socket =
      socket
      |> assign(edit_mode: !socket.assigns.edit_mode)

    {:noreply, socket}
  end

  def handle_event("change_week", %{"value" => value}, socket) do
    selected_week_beginning =
      Timex.shift(socket.assigns.selected_week_beginning, weeks: String.to_integer(value))

    {:noreply,
     load_then_assign_interview_stage_and_changeset(
       socket,
       socket.assigns.interview_stage.id,
       selected_week_beginning
     )}
  end

  defp load_then_assign_interview_stage_and_changeset(
         socket,
         interview_stage_id,
         selected_week_beginning
       ) do
    interview_stage =
      InterviewStages.get_weeks_availability_for_stage(
        interview_stage_id,
        selected_week_beginning
      )

    changeset = InterviewStage.availability_changeset(interview_stage, %{})

    assign(socket,
      selected_week_beginning: selected_week_beginning,
      interview_stage: interview_stage,
      changeset: changeset
    )
  end

  defp find_availability_for_week(start_of_week, availability) do
    Enum.map(0..6, &Date.add(start_of_week, &1))
    |> Enum.map(&{&1, availability |> filter_for_date(&1)})
  end

  defp filter_for_date(availability, date) do
    availability
    |> Enum.filter(fn
      %{date: ^date} ->
        true

      %{start_datetime: nil} ->
        false

      %{start_datetime: start_datetime} ->
        DateTime.to_date(start_datetime) == date
    end)
  end
end
