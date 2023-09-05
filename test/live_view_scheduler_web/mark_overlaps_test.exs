defmodule LiveViewSchedulerWeb.NoOverlapTest do
  use LiveViewSchedulerWeb.ConnCase

  @no_overlaps [
    %{
      "id" => "0",
      "start_datetime" => "2023-08-28 07:45:00.000000Z",
      "end_datetime" => "2023-08-28 09:00:00.000000Z"
    },
    %{
      "id" => "1",
      "start_datetime" => "2023-08-28 10:00:00.000000Z",
      "end_datetime" => "2023-08-28 11:00:00.000000Z"
    }
  ]

  @all_but_one_overlaps [
    %{
      "id" => "0",
      "start_datetime" => "2023-08-28 07:15:00.000000Z",
      "end_datetime" => "2023-08-28 07:45:00.000000Z"
    },
    %{
      "id" => "1",
      "start_datetime" => "2023-08-28 07:15:00.000000Z",
      "end_datetime" => "2023-08-28 08:00:00.000000Z"
    },
    %{
      "id" => "2",
      "start_datetime" => "2023-08-28 07:45:00.000000Z",
      "end_datetime" => "2023-08-28 09:00:00.000000Z"
    },
    # ok
    %{
      "id" => "3",
      "start_datetime" => "2023-08-28 10:00:00.000000Z",
      "end_datetime" => "2023-08-28 11:00:00.000000Z"
    },
    %{
      "id" => "4",
      "start_datetime" => "2023-08-30 07:30:00.000000Z",
      "end_datetime" => "2023-08-30 09:30:00.000000Z"
    },
    %{
      "id" => "5",
      "start_datetime" => "2023-08-30 09:00:00.000000Z",
      "end_datetime" => "2023-08-30 09:15:00.000000Z"
    }
  ]
  @all_overlap [
    %{
      "id" => "0",
      "start_datetime" => "2023-09-25 07:00:00.000000Z",
      "end_datetime" => "2023-09-25 07:30:00.000000Z"
    },
    %{
      "id" => "1",
      "start_datetime" => "2023-09-25 07:00:00.000000Z",
      "end_datetime" => "2023-09-25 07:30:00.000000Z"
    },
    %{
      "id" => "2",
      "start_datetime" => "2023-09-26 07:45:00.000000Z",
      "end_datetime" => "2023-09-26 08:30:00.000000Z"
    },
    %{
      "id" => "3",
      "start_datetime" => "2023-09-26 08:00:00.000000Z",
      "end_datetime" => "2023-09-26 09:00:00.000000Z"
    }
  ]
  @with_incomplete_datetimes [
    %{
      "date" => "2023-09-04",
      "end_datetime" => "2023-09-04 07:45:00.000000Z",
      "id" => "0",
      "interview_stage_id" => "2",
      "start_datetime" => "2023-09-04 07:00:00.000000Z",
      "temp_id" => ""
    },
    %{
      "date" => "2023-09-04",
      "end_datetime" => "2023-09-04 07:30:00.000000Z",
      "id" => "1",
      "interview_stage_id" => "2",
      "start_datetime" => "2023-09-04 07:00:00.000000Z",
      "temp_id" => ""
    },
    %{
      "date" => "2023-09-05",
      "end_datetime" => "",
      "interview_stage_id" => "2",
      "start_datetime" => "",
      "temp_id" => "vVlgm",
      "id" => "2"
    }
  ]
  @with_same_datetimes [
    %{
      "date" => "2023-09-05",
      "end_datetime" => "2023-09-04 07:30:00.000000Z",
      "interview_stage_id" => "2",
      "start_datetime" => "2023-09-04 07:30:00.000000Z",
      "temp_id" => "vVlgm",
      "id" => "0"
    },
    %{
      "date" => "2023-09-05",
      "end_datetime" => "2023-09-04 07:30:00.000000Z",
      "interview_stage_id" => "2",
      "start_datetime" => "2023-09-04 07:30:00.000000Z",
      "temp_id" => "vVlgm",
      "id" => "1"
    }
  ]

  defp extract_results(list) do
    Enum.map(list, &{Map.get(&1, "id"), Map.get(&1, "overlaps")})
  end

  describe "mark_overlaps" do
    test "no overlaps" do
      assert LiveViewScheduler.InterviewStage.mark_overlaps(@no_overlaps)
             |> extract_results() == [
               {"0", false},
               {"1", false}
             ]
    end

    test "all but one overlap" do
      assert LiveViewScheduler.InterviewStage.mark_overlaps(@all_but_one_overlaps)
             |> extract_results() == [
               {"0", true},
               {"1", true},
               {"2", true},
               {"3", false},
               {"4", true},
               {"5", true}
             ]
    end

    test "all overlap" do
      assert LiveViewScheduler.InterviewStage.mark_overlaps(@all_overlap)
             |> extract_results() == [
               {"0", true},
               {"1", true},
               {"2", true},
               {"3", true}
             ]
    end

    test "with incomplete datetimes" do
      assert LiveViewScheduler.InterviewStage.mark_overlaps(@with_incomplete_datetimes)
             |> extract_results() ==
               [
                 {"0", true},
                 {"1", true},
                 {"2", false}
               ]
    end

    test "with same datetimes" do
      assert LiveViewScheduler.InterviewStage.mark_overlaps(@with_same_datetimes)
             |> extract_results() == [
               {"0", false},
               {"1", false}
             ]
    end

    test "with same datetime" do
      assert LiveViewScheduler.InterviewStage.mark_overlaps(Enum.take(@with_same_datetimes, 1))
             |> extract_results() == [{"0", false}]
    end
  end
end
