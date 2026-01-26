defmodule Balance.WindowTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Balance.Window

  describe "add/2" do
    property "simple mathematical properties of non-negative integer aggregation hold up" do
      check all(
              sample_count <- integer(0..600),
              samples <- list_of(positive_integer(), length: sample_count),
              inflight_min <- constant(1),
              inflight_max <- integer(1..50)
            ) do
        inflight_range = inflight_min..inflight_max

        window =
          Enum.reduce(samples, Window.new(), fn sample_value, window ->
            Window.add(
              window,
              {sample_value, Enum.random(inflight_range), Enum.random([true, false])}
            )
          end)

        assert window.sample_count == sample_count

        assert window.max_inflight <= inflight_max
        assert window.max_inflight >= inflight_min

        for sample_value <- samples, do: assert(window.sum >= sample_value)
      end
    end
  end
end
