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

  def assert_all(list, accessor_fn, predicate_fn) do
    list
    |> Enum.map(&accessor_fn.(&1))
    |> Enum.map(&predicate_fn.(&1))
    |> Enum.all?()
  end

  describe "unit tests with emulated Socket" do
    setup [:create_socket, :create_interview_stage, :mount_socket]

    test "creates correct socket", %{socket: socket} do
      assert socket.assigns.interview_stage.__meta__.state == :loaded
      assert socket.assigns.interview_stage.interview_availabilities == []
      assert socket.assigns.changeset.changes == %{}
    end

    test "adds a new empty slot", %{socket: socket} do
      date = Timex.today()
      socket = IA.assign_new_slot_to_changeset(socket, Date.to_iso8601(date))

      # changes happened
      refute socket.assigns.changeset.changes == %{}

      # new_availability has temp_id
      assert socket.assigns.changeset.changes.interview_availabilities
             |> assert_all(fn %{data: data} -> data end, fn data -> is_binary(data.temp_id) end)

      # and is ready for insertion
      assert socket.assigns.changeset.changes.interview_availabilities
             |> assert_all(fn %{action: action} -> action end, fn action -> action == :insert end)
    end

    test "adds two new empty slots for different days", %{socket: socket} do
      date = Timex.today()

      # add two different days
      socket =
        socket
        |> IA.assign_new_slot_to_changeset(Date.to_iso8601(date))
        |> IA.assign_new_slot_to_changeset(Date.to_iso8601(Timex.shift(date, days: 1)))

      # changes happened
      refute socket.assigns.changeset.changes == %{}

      # ready for db insertions
      assert socket.assigns.changeset.changes.interview_availabilities
             |> assert_all(fn %{action: action} -> action end, fn action -> action == :insert end)
    end

    test "saves new interview availability", %{socket: socket} do
      date = Timex.today()

      socket = IA.assign_new_slot_to_changeset(socket, Date.to_iso8601(date))

      new_availability =
        socket.assigns.changeset.changes.interview_availabilities
        |> get_in([Access.at(0), Access.key!(:data)])

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

      assert socket.assigns.interview_stage.interview_availabilities
             |> assert_all(fn %{__meta__: meta} -> meta end, fn meta -> meta.state == :loaded end)
    end

    def add_times_to_slots(
          availabilities,
          start_datetime \\ ~T[07:00:00.000000],
          end_datetime \\ ~T[07:30:00.000000]
        ) do
      interview_availabilities =
        for {%{data: data}, i} <- Enum.with_index(availabilities), into: Map.new() do
          {Integer.to_string(i),
           %{
             "date" => data.date,
             "end_datetime" => DateTime.new!(data.date, end_datetime),
             "interview_stage_id" => Integer.to_string(data.interview_stage_id),
             "start_datetime" => DateTime.new!(data.date, start_datetime),
             "temp_id" => data.temp_id
           }}
        end

      Map.put(%{}, "interview_availabilities", interview_availabilities)
    end

    test "save several new interview availabilities for different non-past dates", %{
      socket: socket
    } do
      date = Timex.today()

      socket =
        socket
        |> IA.assign_new_slot_to_changeset(Date.to_iso8601(date))
        |> IA.assign_new_slot_to_changeset(Date.to_iso8601(Timex.shift(date, days: 1)))

      # emulate adding times to new slots
      interview_availabilities =
        socket.assigns.changeset.changes.interview_availabilities
        |> add_times_to_slots()

      # emulate submitting the form
      socket = IA.save_interview_availabilities(socket, interview_availabilities)

      # new interview availability has been persisted
      refute socket.assigns.interview_stage.interview_availabilities == []

      assert socket.assigns.interview_stage.interview_availabilities
             |> assert_all(fn %{__meta__: meta} -> meta end, fn meta -> meta.state == :loaded end)
    end

    test "success: cannot save two overlapping interview availabilities", %{
      socket: socket
    } do
      date = Timex.today()

      # add same date slots
      socket =
        socket
        |> IA.assign_new_slot_to_changeset(Date.to_iso8601(date))
        |> IA.assign_new_slot_to_changeset(Date.to_iso8601(date))

      # emulate adding times to new slots
      interview_availabilities =
        socket.assigns.changeset.changes.interview_availabilities
        |> add_times_to_slots()

      # emulate submitting the form
      {:error,
       %Ecto.Changeset{
         action: :update,
         changes: changes,
         valid?: false
       }} = IA.save_interview_availabilities(socket, interview_availabilities)

      assert [
               %Ecto.Changeset{
                 action: :insert,
                 errors: [overlaps: {"Cannot overlap with other availabilities", []}],
                 valid?: false
               },
               %Ecto.Changeset{
                 action: :insert,
                 errors: [overlaps: {"Cannot overlap with other availabilities", []}],
                 valid?: false
               }
             ] = changes.interview_availabilities
    end
  end
end
