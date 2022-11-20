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
end
