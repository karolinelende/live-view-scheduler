defmodule LiveViewScheduler.InterviewStage do
  use Ecto.Schema
  import Ecto.Changeset
  alias LiveViewScheduler.InterviewAvailability

  schema "interview_stages" do
    field :name, :string
    field :duration, :integer

    has_many :interview_availabilities, InterviewAvailability,
      on_delete: :delete_all,
      on_replace: :mark_as_invalid


    timestamps(type: :utc_datetime_usec)
  end

  def create_changeset(%__MODULE__{} = interview_stage, attrs) do
    interview_stage
    |> cast(attrs, [:name, :duration])
    |> validate_required([:name, :duration])
  end

  def availability_changeset(
        %__MODULE__{interview_availabilities: interview_availabilities} = interview_stage,
        attrs
      )
      when is_list(interview_availabilities) do
    # Feature4: Not be able to add overlapping interview availabilities for the same day
    # We will go through all new interview_availabilities and
    # add a virtual %{"overlaps": true} to those which overlap.
    # `InterviewAvailability.create_changeset/2` will run `validate_no_overlap/1` to
    # add error message.
    attrs = prepare_interview_availability_attrs(attrs)

    interview_stage
    |> cast(attrs, [])
    |> cast_assoc(
      :interview_availabilities,
      with: fn interview_availability, attributes ->
        %{interview_availability | interview_stage: interview_stage}
        |> InterviewAvailability.create_changeset(attributes)
      end
    )
  end

  #
  defp prepare_interview_availability_attrs(%{
         "interview_availabilities" => attrs
       }) do
    marked_attrs =
      attrs
      |> Map.to_list()
      |> Enum.map(&elem(&1, 1))
      |> mark_overlaps()
      # should test this to see if order holds.
      |> Enum.with_index(fn slot, i -> {Integer.to_string(i), slot} end)
      |> Map.new()

    %{"interview_availabilities" => marked_attrs}
  end

  defp prepare_interview_availability_attrs(%{}), do: %{}
  defp prepare_interview_availability_attrs(attrs), do: attrs

  @doc """
  Adds %{"overlap" => true} to mark an interview_availablility
  attribute as overlapping with any other.
  InterviewAvailability.create_changeset/2 will run validation and
  add errors.
  """
  def mark_overlaps([]), do: []
  def mark_overlaps(list), do: mark_overlaps(list, [])
  def mark_overlaps([], acc), do: Enum.reverse(acc)

  def mark_overlaps([slot | slots], acc) do
    if slots
       |> Enum.map(&overlaps?(slot, &1))
       |> Enum.any?() do
      # we need to mark each remaining slot if it overlaps with the current slot
      slots =
        slots
        |> Enum.map(fn
          %{"overlaps" => true} = val ->
            val

          val ->
            if overlaps?(slot, val),
              do: Map.put(val, "overlaps", true),
              else: val
        end)

      mark_overlaps(slots, [Map.put(slot, "overlaps", true) | acc])
    else
      # we want every slot to be marked
      if Map.get(slot, "overlaps"),
        do: mark_overlaps(slots, [slot | acc]),
        else: mark_overlaps(slots, [Map.put(slot, "overlaps", false) | acc])
    end
  end

  # we only want to run final interval comparison if
  # there are two valid sets of datetimes to compare
  # this checks the first set
  defp overlaps?(a, b) when is_map(a) do
    if Map.get(a, "start_datetime") |> valid_datetime?() and
         Map.get(a, "end_datetime") |> valid_datetime?(),
       do: overlaps?({:ok, a}, b),
       else: false
  end

  # this checks the second
  defp overlaps?({:ok, a}, b) when is_map(b) do
    if Map.get(b, "start_datetime") |> valid_datetime?() and
         Map.get(b, "end_datetime") |> valid_datetime?(),
       do: overlaps?({:ok, a}, {:ok, b}),
       else: false
  end

  # this makes sure that we can build valid Intervals.
  # For instance, when user has set same start/end datetimes
  # Timex.Interval.new cannot handle 0 minute durations
  # we want to mark these slots as %{"overlaps": false} and
  # let changeset's validate_duration/4 to deal with this
  defp overlaps?({:ok, a}, {:ok, b}) do
    with %Timex.Interval{} = interval_a <- make_interval(a),
         %Timex.Interval{} = interval_b <- make_interval(b),
         do: Timex.Interval.overlaps?(interval_a, interval_b)
  end

  defp to_datetime(datetime) when is_binary(datetime) do
    {:ok, date, _} = Elixir.DateTime.from_iso8601(datetime)
    date
  end

  defp to_datetime(datetime), do: datetime

  defp make_interval(slot) when is_map(slot) do
    from =
      slot
      |> Map.get("start_datetime")
      |> to_datetime()

    to =
      slot
      |> Map.get("end_datetime")
      |> to_datetime()

    minutes = Timex.diff(from, to, :minutes)

    case minutes do
      # Timex.Interval.new cannot handle 0 minute intervals
      0 ->
        false

      # happy case
      minutes ->
        Timex.Interval.new(
          from: from,
          until: [minutes: abs(minutes)]
        )
    end
  end

  defp valid_datetime?(""), do: false
  defp valid_datetime?(nil), do: false
  defp valid_datetime?(false), do: false
  defp valid_datetime?(_), do: true
end
