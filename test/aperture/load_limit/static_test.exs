defmodule Aperture.LoadLimit.StaticTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Aperture.LoadLimit.Static
  alias Aperture.Window

  describe "add/2" do
    property "nothing in the config should change, despite changes in concurrency or sampled data" do
      check all(
              static_concurrency_limit <- integer(1..50),
              sample_count <- integer(0..100),
              samples <- list_of(positive_integer(), length: sample_count),
              inflight_min <- constant(1),
              inflight_max <- integer(1..50)
            ) do
        {static_load_config, ^static_concurrency_limit} =
          Static.new(concurrency_limit: static_concurrency_limit)

        inflight_range = inflight_min..inflight_max

        window =
          Enum.reduce(samples, Window.new(), fn sample_value, window ->
            Window.add(
              window,
              {sample_value, Enum.random(inflight_range), Enum.random([true, false])}
            )
          end)

        {static_load_config, ^static_concurrency_limit} =
          Static.update(static_load_config, static_concurrency_limit, window)

        assert static_load_config.concurrency_limit == static_concurrency_limit
      end
    end
  end
end
