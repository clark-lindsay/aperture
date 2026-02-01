defmodule Aperture.Math do
  @moduledoc false

  @spec clamp(number :: number(), min: number(), max: number(), set: :integers) :: number()
  def clamp(number, opts) do
    set = opts[:set] || :real
    # Numbers will always compare "less than" atoms, since `max/2` uses
    # structural comparison
    maximum = opts[:max] || nil

    number =
      case opts[:min] do
        nil ->
          min(number, maximum)

        minimum when is_number(minimum) ->
          if maximum < minimum, do: raise(ArgumentError, message: "max must be >= min")

          min(maximum, max(minimum, number))
      end

    case set do
      :real -> number
      :integers -> trunc(number)
    end
  end
end
