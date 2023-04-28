defmodule LiveViewSchedulerWeb.InterviewAvailabilityLive.FormComponents do
  use LiveViewSchedulerWeb, :component

  def show_availability(assigns) do
    ~H"""
    <div>View mode</div>
    <.week_select selected_week_beginning={@selected_week_beginning} />
    <%= for {date, slots} <- @availability_for_week do %>
      <.day_availability date={date} slots={slots} />
    <% end %>
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

  def day_availability(assigns) do
    ~H"""
    <div class="flex">
      <div class="m-8">
        <span><%= @date %></span>
      </div>
      <%= if @slots == [] do %>
        <div class="m-8">No availability added</div>
      <% else %>
        <div class="m-8">
          <%= for %{start_datetime: start_time, end_datetime: end_time} <- @slots do %>
            <div>
              <%= format_time_window(start_time, end_time) %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end

  def edit_availability(assigns) do
    ~H"""
    <div>Edit mode</div>
    <button phx-click="toggle-edit-mode">Cancel</button>
    """
  end

  def format_time_window(start_time, end_time),
    do: "#{format_time_12h(start_time)} – #{format_time_12h(end_time)}"

  def format_time_12h(datetime), do: Timex.format!(datetime, "{h12}:{m}{am}")
end
