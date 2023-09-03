defmodule InterviewAvailabilityLiveTest do
  use LiveViewSchedulerWeb.ConnCase
  alias LiveViewScheduler.{InterviewStages, InterviewStage}
  alias LiveViewSchedulerWeb.InterviewAvailabilityLive.Index, as: IA

  def create_socket(_), do: %{socket: %Phoenix.LiveView.Socket{}}

  @create_attrs %{
    name: "test",
    duration: 30
  }

  def assert_key(socket, key, value) do
    assert socket.assigns[key] == value
    socket
  end

  def create_interview_stage(_) do
    {:ok, %InterviewStage{} = interview_stage} =
      InterviewStages.create_interview_stage(@create_attrs)

    [interview_stage: interview_stage]
  end

  def mount_socket(%{socket: socket, interview_stage: interview_stage}) do
    selected_week_beginning = Timex.today()

    interview_stage = IA.get_interview_stage(interview_stage.id, selected_week_beginning)

    socket =
      socket
      |> IA.assign_interview_stage(interview_stage)
      |> IA.assign_edit_mode(true)
      |> IA.assign_selected_week_beginning(selected_week_beginning)
      |> IA.assign_changeset()

    [socket: socket]
  end

  defp extract_new_availability(socket) do
    socket.assigns.changeset.changes.interview_availabilities
    |> Enum.at(0)
    |> Map.get(:data)
  end

  describe "unit tests with emulated Socket" do
    setup [:create_socket, :create_interview_stage, :mount_socket]

    test "adds a new empty slot", %{socket: socket} do
      date = Timex.today()

      assert socket.assigns.interview_stage.__meta__.state == :loaded
      assert socket.assigns.interview_stage.interview_availabilities == []
      assert socket.assigns.changeset.changes == %{}

      socket = IA.assign_new_slot_to_changeset(socket, Date.to_iso8601(date))

      # changes happened
      refute socket.assigns.changeset.changes == %{}

      # look at new_availability
      new_availability = extract_new_availability(socket)

      assert is_binary(new_availability.temp_id)
    end

    test "saves new interview availability", %{socket: socket} do
      date = Timex.today()

      socket = IA.assign_new_slot_to_changeset(socket, Date.to_iso8601(date))

      new_availability = extract_new_availability(socket)

      # emulate adding times to new slot
      interview_availabilities = %{
        "interview_availabilities" => %{
          "0" => %{
            "date" => date,
            "end_datetime" => DateTime.new!(date, ~T[07:30:00.000000]),
            "interview_stage_id" => Integer.to_string(new_availability.interview_stage_id),
            "start_datetime" => DateTime.new!(date, ~T[07:00:00.000000]),
            "temp_id" => new_availability.temp_id
          }
        }
      }

      # emulate submitting the form
      socket = IA.save_interview_availabilities(socket, interview_availabilities)

      # new interview availability has been persisted
      refute socket.assigns.interview_stage.interview_availabilities == []
    end
  end
end
