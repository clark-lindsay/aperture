defmodule Modulator.Window do
  @moduledoc """
  Tracks a set of samples, ideally over some continuous window of time. This window
  is used to derive new concurrency limits.

  These samples could be of any metric, but the most commond would be
  "round-trip-time". I would recommend using the highest precision unit
  available to the operating system (`:native` time units), avoiding floating
  point values by whatever means are appropriate, and then possibly converting
  those high precision units into a lower precision unit (e.g. nanoseconds ->
  seconds) if necessary.
  """

  @type t :: %{
          sum: pos_integer(),
          min_sample: pos_integer(),
          max_inflight: pos_integer(),
          sample_count: pos_integer(),
          did_drop?: boolean()
        }

  def new do
    %{
      # The sum value for all samples
      sum: 0,
      # min sample value seen
      min_sample: nil,

      # Max in-flight requests
      max_inflight: 0,
      sample_count: 0,

      # Did we drop a request in this window?
      did_drop?: false
    }
  end

  @spec add(
          window :: t(),
          {sample_value :: pos_integer(), inflight_count :: pos_integer(),
           was_dropped? :: boolean()}
        ) :: t()
  def add(window, {sample_value, inflight_count, was_dropped?}) do
    window
    |> Map.update!(:sum, &(&1 + sample_value))
    |> Map.update!(:min_sample, &if(&1 == nil, do: sample_value, else: min(&1, sample_value)))
    |> Map.update!(:max_inflight, &max(&1, inflight_count))
    |> Map.update!(:sample_count, &(&1 + 1))
    |> Map.update!(:did_drop?, &(&1 || was_dropped?))
  end

  def avg_value(%{sum: sum, sample_count: sample_count}) do
    if sample_count == 0 do
      0
    else
      Integer.floor_div(sum, sample_count)
    end
  end
end
