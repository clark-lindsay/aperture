defmodule Aperture.LoadLimit.GradientTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Aperture.LoadLimit.Gradient
  alias Aperture.Window

  # TODO: It feels odd that we don't account for whether or not any requests were dropped...?
  # TODO: Doesn't seem to be very sensitive at all to input, WRT changing the
  # concurrency limit, even though the smoothed values appear to track neatly
  # Seems more sensitive the larger the range of variation in input samples
  # Maybe an error in my implementation of the algorithm.
  # I think I'm not appropriately accounting for the long term average value,
  # which would explain why it seems to be having this "frog soup" slow boil problem
  describe "add/2" do
    property "continually rising samples (averaged over a window) should produce a monotonic decreasing concurrency limit" do
      check all(
              initial_concurrency_limit <- constant(100),
              window_count <- integer(1..100),
              samples_per_window <- list_of(positive_integer(), length: window_count),
              # usually someting like RTT in microseconds
              window_avgs <- list_of(member_of(1_000..10_000_000), length: window_count),
              inflight_max <- integer(1..50)
            ) do
        windows =
          for {avg, sample_count} <- Enum.zip(Enum.sort(window_avgs, :asc), samples_per_window) do
            %{
              Window.new()
              | sum: avg * sample_count,
                min_sample: 1,
                max_inflight: inflight_max,
                sample_count: sample_count,
                did_drop?: Enum.random([true, false])
            }
          end

        # Intentionally leaving all optional options to their default values
        {gradient_config, ^initial_concurrency_limit} =
          Gradient.new(initial_concurrency_limit: initial_concurrency_limit)

        for window <- windows, reduce: gradient_config do
          config ->
            previous_concurrency_limit = config.estimated_concurrency_limit

            {config, new_concurrency_limit} =
              Gradient.update(config, previous_concurrency_limit, window)

            assert new_concurrency_limit <= previous_concurrency_limit

            config
        end
      end
    end

    # TODO: Concurrency never seems to grow...
    # is that right? does the algorithm only account for contractions?
    property "continually falling samples (averaged over a window) should produce a monotonic increasing concurrency limit" do
      check all(
              initial_concurrency_limit <- constant(5),
              window_count <- integer(1..100),
              samples_per_window <- list_of(positive_integer(), length: window_count),
              # usually someting like RTT in microseconds
              window_avgs <- list_of(member_of(1_000..10_000_000), length: window_count),
              inflight_max <- integer(1..50)
            ) do
        windows =
          for {avg, sample_count} <- Enum.zip(Enum.sort(window_avgs, :desc), samples_per_window) do
            %{
              Window.new()
              | sum: avg * sample_count,
                min_sample: 1,
                max_inflight: inflight_max,
                sample_count: sample_count,
                did_drop?: Enum.random([true, false])
            }
          end

        # Intentionally leaving all optional options to their default values
        {gradient_config, ^initial_concurrency_limit} =
          Gradient.new(initial_concurrency_limit: initial_concurrency_limit)

        for window <- windows, reduce: gradient_config do
          config ->
            previous_concurrency_limit = config.estimated_concurrency_limit

            {config, new_concurrency_limit} =
              Gradient.update(config, previous_concurrency_limit, window)

            assert new_concurrency_limit >= previous_concurrency_limit

            config
        end
      end
    end
  end
end
