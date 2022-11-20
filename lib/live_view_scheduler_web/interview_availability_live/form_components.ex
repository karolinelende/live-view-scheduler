defmodule LiveViewSchedulerWeb.InterviewAvailabilityLive.FormComponents do
  use LiveViewSchedulerWeb, :component

  def show_availability(assigns) do
    ~H"""
    <div> View mode </div>
    <button phx-click="toggle-edit-mode"> Edit </button>
    """
  end

  def edit_availability(assigns) do
    ~H"""
    <div> Edit mode </div>
    """
  end
end
