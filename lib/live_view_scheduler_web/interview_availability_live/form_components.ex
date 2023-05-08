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

  def format_time_window(start_time, end_time),
    do: "#{format_time_12h(start_time)} – #{format_time_12h(end_time)}"

  def format_time_12h(datetime), do: Timex.format!(datetime, "{h12}:{m}{am}")

  def edit_availability(assigns) do
    ~H"""
    <div>Edit mode</div>
    <h3>Week beginning: <%= @selected_week_beginning %></h3>
    <.form let={f} for={@changeset} id="availability-form" phx-change="change-time" phx-submit="save">
      <%= for {date, slot_forms} <- group_availability(f, @selected_week_beginning) do %>
        <.edit_day_availability {assigns_to_attributes(assigns)} date={date} slot_forms={slot_forms} />
      <% end %>
      <button type="button" class="bg-gray" phx-click="toggle-edit-mode">Cancel</button>
      <button type="submit">Save</button>
    </.form>
    """
  end

  defp group_availability(form, start_of_week) do
    week_availabilities = inputs_for(form, :interview_availabilities)

    Enum.map(0..6, &Date.add(start_of_week, &1))
    |> Enum.map(&{&1, filter_for_date(&1, week_availabilities)})
  end

  defp filter_for_date(date, week_availabilities) do
    week_availabilities
    |> Enum.filter(fn availability_form ->
      availability_date =
        case input_value(availability_form, :date) do
          %Date{} = x -> x
          x when is_binary(x) -> Date.from_iso8601!(x)
        end

      availability_date == date
    end)
  end

  defp edit_day_availability(assigns) do
    all_deleted = Enum.all?(assigns.slot_forms, &(input_value(&1, :deleted) == true))
    assigns = assign(assigns, :all_deleted, all_deleted)

    ~H"""
    <div class="flex">
      <div class="m-8">
        <span><%= @date %></span>
      </div>
      <div class="flex">
        <div>
          <%= case @slot_forms do %>
            <% [] -> %>
              <span class="m-8">No availability added</span>
            <% slot_forms -> %>
              <%= if @all_deleted do %>
                <span class="m-8">No availability added</span>
              <% end %>
              <%= Enum.sort_by(slot_forms, &(input_value(&1, :deleted) != true)) |> Enum.map(fn slot_form -> %>
                <%= if input_value(slot_form, :deleted) == true do %>
                  <%= hidden_inputs_for(slot_form) %>
                  <%= hidden_input(slot_form, :deleted) %>
                <% else %>
                  <fieldset>
                    <%= hidden_inputs_for(slot_form) %>
                    <%= hidden_input(slot_form, :temp_id) %>
                    <%= hidden_input(slot_form, :date) %>
                    <%= hidden_input(slot_form, :interview_stage_id) %>
                    <div>
                      <.future_slot slot_form={slot_form} date={@date} />
                    </div>
                  </fieldset>
                <% end %>
              <% end) %>
          <% end %>
        </div>
        <button type="button" phx-value-selected-day={@date} phx-click="new-slot" class="m-8">
          +
        </button>
      </div>
    </div>
    """
  end

  defp future_slot(assigns) do
    assigns =
      assign(assigns,
        id: input_value(assigns.slot_form, :id) || input_value(assigns.slot_form, :temp_id)
      )

    ~H"""
    <div class="flex">
      <.time_select id={@id} slot_form={@slot_form} field={:start_datetime} date={@date} />
      <span class="m-8">-</span>
      <.time_select id={@id} slot_form={@slot_form} field={:end_datetime} date={@date} />
      <button type="button" phx-value-index={@slot_form.index} phx-click="delete-slot" class="m-8">
        🗑
      </button>
    </div>
    """
  end

  defp time_select(assigns) do
    input_value(assigns.slot_form, assigns.field)

    assigns =
      assign(
        assigns,
        :selected,
        case input_value(assigns.slot_form, assigns.field) do
          %DateTime{} = d -> d |> to_string
          d when is_binary(d) -> d
          _ -> nil
        end
      )

    ~H"""
    <div>
      <select id={"slot-#{@id}-#{@field}"} name={input_name(@slot_form, @field)}>
        <%= options_for_select(
          [{"#{humanize(@field)}", nil} | generate_time_options(@date)],
          @selected
        ) %>
      </select>
      <%= error_tag(@slot_form, @field) %>
    </div>
    """
  end

  defp generate_time_options(date) do
    DateTime.new!(date, ~T[07:00:00.000000])
    |> Stream.iterate(&Timex.shift(&1, minutes: 15))
    |> Enum.take_while(&(DateTime.compare(&1, DateTime.new!(date, ~T[20:00:00.000000])) != :gt))
    |> Enum.map(&{"#{format_time_12h(&1)}", DateTime.to_string(&1)})
  end
end
