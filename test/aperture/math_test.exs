defmodule Aperture.MathTest do
  use ExUnit.Case
  use ExUnitProperties

  alias Aperture.Math

  describe "clamp/2" do
    setup do
      [
        minus_hundred_billion: -100_000_000_000,
        hundred_billion: 100_000_000_000
      ]
    end

    property "the result is always in the expected range with valid min and max provided or left out",
             ctx do
      check all(
              input <- one_of([integer(), float()]),
              random_divider <- integer(Range.new(ctx.minus_hundred_billion, ctx.hundred_billion)),
              min <-
                one_of([
                  integer(Range.new(ctx.minus_hundred_billion - 1, random_divider, 1)),
                  float(max: random_divider)
                ]),
              max <-
                one_of([
                  integer(Range.new(random_divider, ctx.hundred_billion + 1, 1)),
                  float(min: random_divider)
                ])
            ) do
        output = Math.clamp(input, min: min, max: max)

        assert output >= min
        assert output <= max

        no_min_output = Math.clamp(input, max: max)

        assert no_min_output <= max
        # The value should have only decreased, if it changed at all
        assert no_min_output <= input

        no_max_output = Math.clamp(input, min: min)

        assert no_max_output >= min
        # The value should have only increased, if it changed at all
        assert no_max_output >= input
      end
    end

    property "coerces the result to the desired set of numbers", ctx do
      check all(
              input <- one_of([integer(), float()]),
              random_divider <- integer(Range.new(ctx.minus_hundred_billion, ctx.hundred_billion)),
              min <-
                one_of([
                  integer(Range.new(ctx.minus_hundred_billion - 1, random_divider, 1)),
                  float(max: random_divider)
                ]),
              max <-
                one_of([
                  integer(Range.new(random_divider, ctx.hundred_billion + 1, 1)),
                  float(min: random_divider)
                ])
            ) do
        for args <- [
              [input, [min: min, max: max, set: :integers]],
              [input, [max: max, set: :integers]],
              [input, [set: :integers]]
            ] do
          assert is_integer(Kernel.apply(Math, :clamp, args))
        end

        for args <- [
              [input, [min: min, max: max, set: :real]],
              [input, [max: max, set: :real]],
              [input, [set: :real]]
            ] do
          assert is_number(Kernel.apply(Math, :clamp, args))
        end
      end
    end
  end
end
