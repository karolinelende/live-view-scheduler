defmodule LiveViewSchedulerWeb.InterviewAvailabilityLive.Index do
  use Phoenix.LiveView, layout: {LiveViewSchedulerWeb.LayoutView, "live.html"}
  alias Ecto.Changeset
  alias LiveViewSchedulerWeb.InterviewAvailabilityLive.FormComponents
  alias LiveViewScheduler.{InterviewStage, InterviewStages}
  alias LiveViewScheduler.Repo

  def mount(%{"interview_stage_id" => interview_stage_id}, _session, socket) do
    selected_week_beginning = Timex.beginning_of_week(Date.utc_today())

    interview_stage =
      InterviewStages.get_weeks_availability_for_stage(
        interview_stage_id,
        selected_week_beginning
      )

    changeset = InterviewStage.availability_changeset(interview_stage, %{})

    socket =
      socket
      |> assign(interview_stage: interview_stage)
      |> assign(edit_mode: false)
      |> assign(selected_week_beginning: selected_week_beginning)
      |> assign(changeset: changeset)

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

    changeset = InterviewStage.availability_changeset(interview_stage, %{})

    socket =
      socket
      |> assign(selected_week_beginning: selected_week_beginning)
      |> assign(interview_stage: interview_stage)
      |> assign(changeset: changeset)

    {:noreply, socket}
  end

  def handle_event(
        "new-slot",
        %{"selected-day" => selected_day},
        %{
          assigns: %{
            interview_stage: interview_stage,
            changeset: changeset
          }
        } = socket
      ) do
    date = Date.from_iso8601!(selected_day)

    existing_availability =
      Changeset.get_change(
        changeset,
        :interview_availabilities,
        Changeset.get_field(changeset, :interview_availabilities)
      )

    new_availability =
      Ecto.build_assoc(interview_stage, :interview_availabilities, %{
        temp_id: :crypto.strong_rand_bytes(5) |> Base.url_encode64() |> binary_part(0, 5),
        date: date,
        start_datetime: nil,
        end_datetime: nil
      })

    changeset =
      Changeset.put_assoc(
        changeset,
        :interview_availabilities,
        existing_availability ++ [new_availability]
      )

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("change-time", %{"interview_stage" => interview_stage}, socket) do
    changeset =
      InterviewStage.availability_changeset(socket.assigns.interview_stage, interview_stage)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"interview_stage" => interview_stage}, socket) do
    socket =
      InterviewStage.availability_changeset(socket.assigns.interview_stage, interview_stage)
      |> Repo.update()
      |> case do
        {:ok, %InterviewStage{} = updated_interview_stage} ->
          socket
          |> assign(edit_mode: false)
          |> assign(:interview_stage, updated_interview_stage)
          |> assign(
            :changeset,
            InterviewStage.availability_changeset(updated_interview_stage, %{})
          )
          |> clear_flash(:error)
          |> put_flash(:info, "Availability saved")

        {:error, changeset} ->
          socket
          |> put_flash(:error, "Error saving availability")
          |> assign(changeset: changeset)
      end

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
