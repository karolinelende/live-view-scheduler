defmodule LiveViewSchedulerWeb.InterviewAvailabilityLive.Index do
  use Phoenix.LiveView
  alias LiveViewSchedulerWeb.InterviewAvailabilityLive.FormComponents
  alias LiveViewScheduler.InterviewStages

  def mount(%{"interview_stage_id" => interview_stage_id}, _session, socket) do
    interview_stage = InterviewStages.get_by_id!(interview_stage_id)

    socket =
      socket
      |> assign(interview_stage: interview_stage)
      |> assign(edit_mode: false)

    {:ok, socket}
  end

  def handle_event("toggle-edit-mode", _, socket) do
    socket =
      socket
      |> assign(edit_mode: !socket.assigns.edit_mode)

    {:noreply, socket}
  end
end
