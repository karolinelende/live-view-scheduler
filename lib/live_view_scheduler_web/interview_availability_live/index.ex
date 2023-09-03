defmodule LiveViewSchedulerWeb.InterviewAvailabilityLive.Index do
  use Phoenix.LiveView, layout: {LiveViewSchedulerWeb.LayoutView, "live.html"}
  alias Ecto.Changeset
  alias LiveViewSchedulerWeb.InterviewAvailabilityLive.FormComponents
  alias LiveViewScheduler.{InterviewStage, InterviewStages}
  alias LiveViewScheduler.Repo

  def mount(%{"interview_stage_id" => interview_stage_id}, _session, socket) do
    selected_week_beginning = Timex.beginning_of_week(Date.utc_today())
    interview_stage = get_interview_stage(interview_stage_id, selected_week_beginning)

    socket =
      socket
      |> assign_interview_stage(interview_stage)
      |> assign_edit_mode(false)
      |> assign_selected_week_beginning(selected_week_beginning)
      |> assign_changeset()

    {:ok, socket}
  end

  def mount(params, session, socket) do
    IO.inspect(params, label: "#{__MODULE__} mounted params")
    IO.inspect(session, label: "#{__MODULE__} mounted session")
    IO.inspect(socket, label: "#{__MODULE__} mounted socket")
    {:ok, socket}
  end

  def handle_event("toggle-edit-mode", _, socket) do
    {:noreply, assign(socket, edit_mode: !socket.assigns.edit_mode) |> clear_flash(:info)}
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
        socket
      ) do
    {:noreply, assign_new_slot_to_changeset(socket, selected_day)}
  end

  def handle_event("change-time", %{"interview_stage" => interview_stage}, socket) do
    changeset =
      InterviewStage.availability_changeset(socket.assigns.interview_stage, interview_stage)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event(
        "delete-slot",
        %{"index" => index},
        %{assigns: %{changeset: changeset}} = socket
      ) do
    index = String.to_integer(index)

    existing_availability =
      Changeset.get_change(
        changeset,
        :interview_availabilities,
        Changeset.get_field(changeset, :interview_availabilities)
      )

    slot_to_delete = Enum.at(existing_availability, index)

    updated_availability =
      if availability_is_already_persisted?(slot_to_delete) do
        existing_availability
        |> List.update_at(index, &Changeset.change(&1, %{deleted: true}))
      else
        List.delete_at(existing_availability, index)
      end

    changeset = Changeset.put_assoc(changeset, :interview_availabilities, updated_availability)

    {:noreply, assign(socket, changeset: changeset)}
  end

  def handle_event("save", %{"interview_stage" => interview_stage}, socket) do
    # leave all flash-related stuff here for testing purposes
    # as we won't have the flash functionality in our test socket
    case save_interview_availabilities(socket, interview_stage) do
      {:error, changeset} ->
        socket
        |> put_flash(:error, "Error saving availability")
        |> assign(changeset: changeset)

      socket ->
        socket
        |> clear_flash(:error)
        |> put_flash(:info, "Availability saved")

        {:noreply, socket}
    end
  end

  def handle_event(event, params, socket) do
    IO.inspect(event, label: "#{__MODULE__} event")
    IO.inspect(params, label: "#{__MODULE__} params")
    IO.inspect(socket, label: "#{__MODULE__} socket")
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

  defp availability_is_already_persisted?(%Changeset{} = changeset) do
    changeset
    |> Changeset.apply_changes()
    |> availability_is_already_persisted?()
  end

  defp availability_is_already_persisted?(%{temp_id: nil}), do: true
  defp availability_is_already_persisted?(_), do: false

  @doc """
  Extracted these as public functions for unit testing.
  """
  def get_interview_stage(interview_stage_id, selected_week_beginning) do
    InterviewStages.get_weeks_availability_for_stage(
      interview_stage_id,
      selected_week_beginning
    )
  end

  def assign_interview_stage(socket, interview_stage) do
    assign(socket, :interview_stage, interview_stage)
  end

  def assign_edit_mode(socket, edit_mode) do
    assign(socket, :edit_mode, edit_mode)
  end

  def assign_selected_week_beginning(socket, date) do
    assign(socket, :selected_week_beginning, date)
  end

  def assign_changeset(%{assigns: %{interview_stage: interview_stage}} = socket) do
    assign(socket, :changeset, InterviewStage.availability_changeset(interview_stage, %{}))
  end

  def assign_changeset(socket, changeset) do
    assign(socket, :changeset, changeset)
  end

  def build_new_availability(%InterviewStage{} = interview_stage, date) do
    Ecto.build_assoc(interview_stage, :interview_availabilities, %{
      temp_id: :crypto.strong_rand_bytes(5) |> Base.url_encode64() |> binary_part(0, 5),
      date: Date.from_iso8601!(date),
      start_datetime: nil,
      end_datetime: nil
    })
  end

  def get_existing_availability(changeset) do
    Changeset.get_change(
      changeset,
      :interview_availabilities,
      Changeset.get_field(changeset, :interview_availabilities)
    )
  end

  @spec update_interview_availabilities(Ecto.Changeset.t(), any) :: Ecto.Changeset.t()
  def update_interview_availabilities(changeset, updated_availabilities) do
    Changeset.put_assoc(
      changeset,
      :interview_availabilities,
      updated_availabilities
    )
  end

  def assign_new_slot_to_changeset(
        %{
          assigns: %{
            interview_stage: interview_stage,
            changeset: changeset
          }
        } = socket,
        selected_day
      ) do
    new_availability = build_new_availability(interview_stage, selected_day)
    existing_availability = get_existing_availability(changeset)

    changeset =
      update_interview_availabilities(changeset, existing_availability ++ [new_availability])

    assign_changeset(socket, changeset)
  end

  def save_interview_availabilities(socket, interview_stage) do
    InterviewStage.availability_changeset(socket.assigns.interview_stage, interview_stage)
    |> Repo.update()
    |> case do
      {:ok, %InterviewStage{}} ->
        updated_interview_stage =
          InterviewStages.get_weeks_availability_for_stage(
            socket.assigns.interview_stage.id,
            socket.assigns.selected_week_beginning
          )

        socket
        |> assign(edit_mode: false)
        |> assign(:interview_stage, updated_interview_stage)
        |> assign(
          :changeset,
          InterviewStage.availability_changeset(updated_interview_stage, %{})
        )

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
