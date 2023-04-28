defmodule LiveViewSchedulerWeb.InterviewAvailabilityLive.Index do
  use Phoenix.LiveView
  alias LiveViewSchedulerWeb.InterviewAvailabilityLive.FormComponents
  alias LiveViewScheduler.InterviewStages

  def mount(%{"interview_stage_id" => interview_stage_id}, _session, socket) do
    selected_week_beginning = Timex.beginning_of_week(Date.utc_today())

    interview_stage =
      InterviewStages.get_weeks_availability_for_stage(
        interview_stage_id,
        selected_week_beginning
      )

    socket =
      socket
      |> assign(interview_stage: interview_stage)
      |> assign(edit_mode: false)
      |> assign(selected_week_beginning: selected_week_beginning)

    {:ok, socket}
  end

  def handle_event("toggle-edit-mode", _, socket) do
    {:noreply, assign(socket, edit_mode: !socket.assigns.edit_mode)}
  end

  def handle_event("change_week", %{"value" => value}, socket) do
    selected_week_beginning =
      Timex.shift(socket.assigns.selected_week_beginning, weeks: String.to_integer(value))

    interview_stage =
      InterviewStages.get_weeks_availability_for_stage(
        socket.assigns.interview_stage.id,
        selected_week_beginning
      )

    socket =
      socket
      |> assign(selected_week_beginning: selected_week_beginning)
      |> assign(interview_stage: interview_stage)

    {:noreply, socket}
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

      _ ->
        false
    end)
  end
end
