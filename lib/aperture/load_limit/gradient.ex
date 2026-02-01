defmodule Aperture.LoadLimit.Gradient do
  @moduledoc """
  Hysteretic Gradient limit, which uses (simple) Exponential Smoothing to incorporate past data, while maintaining a bias for more recent data.

  The specific algorithm employed is often attributed to Robert Goodell Brown,
  as "Brown's simple exponential smoothing", but has its basis in works
  attributed to Poisson as well as other more recent mathematicians.

  It's essentially a weighted average of the most recent smoothed measurement,
  and the current sample measurement.

  ```
  # With a `recency_bias_factor` in the range [0, 1],
  # with 0 placing all weight on historical data,
  # and 1 placing all weight on the current sample 
  smoothed_value(time) =
    recency_bias_factor
    * sample_value(time)
    + (
        (1 - recency_bias_factor)
        * smoothed_value(time - 1)
      )
  ```

  The `recency_bias_factor` is usually called the "smoothing factor" in
  literature, but such a name is actually very confusing, as values closer to
  `1` have a ***weaker smoothing effect***.

  See the [wikipedia page](https://en.wikipedia.org/wiki/Exponential_smoothing)
  for more info.

  """

  alias Aperture.Window

  @behaviour Aperture.LoadLimit

  @doc """

  ## Options

  * `:initial_concurrency_limit` (Required) - Estimated limit to use a base line
  * `:recency_bias_factor` - How much weight to place on the most recent data. Must be in the range `[0, 1]`, with values closer to `1` placing more weight on more recent data. Defaults to `0.2`.
  * `:warmup_window` - Number of sample windows before we start applying exponential smoothing, using a simple average instead. This keeps the limit from getting jumpy at start-up. Defaults to 6.
  """
  # TODO: Recovery multiplier? For when the smoothed value far exceeds the most recent sample window
  @impl true
  def new(opts) do
    initial_configuration = %{
      estimated_concurrency_limit: Access.fetch!(opts, :initial_concurrency_limit),
      recency_bias_factor: opts[:recency_bias_factor] || 0.6,
      warmup_window: opts[:warmup_window] || 6,
      smoothed_value: nil,
      iterations: 0
    }

    {initial_configuration, initial_configuration.estimated_concurrency_limit}
  end

  @impl true
  def update(gradient_config, _current_concurrency_limit, window) when window.sample_count == 0 do
    {gradient_config, gradient_config.estimated_concurrency_limit}
  end

  def update(gradient_config, _current_concurrency_limit, window) when window.sample_count > 0 do
    gradient_config = Map.update!(gradient_config, :iterations, &Kernel.+(&1, 1))
    sample_value = Window.avg_value(window)
    smoothed_value = gradient_config.smoothed_value || sample_value

    new_smoothed_value =
      gradient_config.recency_bias_factor *
        sample_value +
        (1 - gradient_config.recency_bias_factor) *
          smoothed_value

    new_smoothed_value =
      if new_smoothed_value > sample_value * 2 do
        clamp_positive(new_smoothed_value * 0.95)
      else
        clamp_positive(new_smoothed_value)
      end

    # TODO: If we are a factor of 2 shy on inflight then
    # we could leave it alone, or even shrink it more dramatically...
    # how much will it shrink on its own, in that case?
    # TODO: Add to configuration, with docs
    # TODO: read up more on the gradient part of the algorithm
    value_deviation_tolerance = 1.5

    # Basically draw a line between the two points, then walk a certain amount
    # along that line towards the new value based on the `recency_bias_factor`
    # TODO: If the max gradient is 1, then I think the concurrency can never grow... right?
    gradient =
      max(0.5, min(1.0, value_deviation_tolerance * new_smoothed_value / sample_value))

    new_estimated_limit =
      gradient_config.estimated_concurrency_limit * (1 - gradient_config.recency_bias_factor) +
        gradient * gradient_config.estimated_concurrency_limit *
          gradient_config.recency_bias_factor

    new_estimated_limit = clamp_positive(new_estimated_limit)

    if new_estimated_limit != gradient_config.estimated_concurrency_limit do
      IO.inspect(%{
        new_estimated_limit: new_estimated_limit,
        estimated_concurrency_limit: gradient_config.estimated_concurrency_limit,
        gradient: gradient,
        sample_value: sample_value,
        new_smoothed_value: new_smoothed_value,
        old_smoothed_value: smoothed_value
      })
    end

    {%{
       gradient_config
       | smoothed_value: new_smoothed_value,
         estimated_concurrency_limit: new_estimated_limit
     }, new_estimated_limit}
  end

  # A concurrency limit of 0 would lock up whatever is being limited, which
  # this module assumes is accidental or a result of a transient jump in the
  # data.
  # And floats are not worth dealing with. If we leave a touch of throughput on
  # the table by rounding down a float, we can just call that "head room"
  defp clamp_positive(value) do
    max(1, trunc(value))
  end
end
