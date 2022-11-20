defmodule LiveViewSchedulerWeb.InterviewAvailabilityLive.FormComponents do
  use LiveViewSchedulerWeb, :component

  def show_availability(assigns) do
    ~H"""
    <div>View mode</div>
    <.week_select selected_week_beginning={@selected_week_beginning} />
    <button phx-click="toggle-edit-mode">Edit</button>
    """
  end

  defp week_select(assigns) do
    ~H"""
    <div>
      <h3>Week beginning: <%= @selected_week_beginning %></h3>
      <div>
        <button phx-click="change_week" value="-1">
          <span>← Previous week</span>
        </button>
        <button phx-click="change_week" value="1">
          <span>Next week →</span>
        </button>
      </div>
    </div>
    """
  end

  def edit_availability(assigns) do
    ~H"""
    <div>Edit mode</div>
    <button phx-click="toggle-edit-mode">Cancel</button>
    """
  end
end
