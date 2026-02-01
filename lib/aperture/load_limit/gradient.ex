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

  What I have called the  `recency_bias_factor` is usually called the
  "smoothing factor" in literature, but such a name is actually very confusing,
  as values closer to `1` have a ***weaker smoothing effect*** than values
  closer to `0`.

  See the [wikipedia page](https://en.wikipedia.org/wiki/Exponential_smoothing)
  for more info.

  """

  alias Aperture.Window
  alias Aperture.Math

  @behaviour Aperture.LoadLimit

  @doc """

  ## Options

  * `:initial_concurrency_limit` (Required) - Estimated limit to use a base line
  * `:max_concurrency_limit` - Maximum acceptable concurrency. Defaults to `50`.
  * `:min_concurrency_limit` - Lowest acceptable concurrency. Defaults to `0`.
  * `:recency_bias_factor` - How much weight to place on the most recent data. Must be in the range `[0, 1]`, with values closer to `1` placing more weight on more recent data. Defaults to `0.2`.
  * `:warmup_window` - Number of sample windows before we start applying exponential smoothing, using a simple average instead. This keeps the limit from getting jumpy at start-up. Defaults to 6.
  """
  # TODO: Recovery multiplier? For when the smoothed value far exceeds the most recent sample window,
  # indicating that the system has probably recovered from an overload
  @impl true
  def new(opts) do
    initial_configuration = %{
      estimated_concurrency_limit:
        Math.clamp(Access.fetch!(opts, :initial_concurrency_limit), min: 0, set: :integers),
      iterations: 0,
      max_concurrency_limit:
        Math.clamp(opts[:max_concurrency_limit] || 50, min: 0, set: :integers),
      min_concurrency_limit:
        Math.clamp(opts[:min_concurrency_limit] || 0, min: 0, set: :integers),
      recency_bias_factor: Math.clamp(opts[:recency_bias_factor] || 0.3, min: 0, max: 1.0),
      smoothed_value: nil,
      warmup_window: opts[:warmup_window] || 6
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
      if gradient_config.iterations < gradient_config.warmup_window do
        sample_weight = 1 / (1 + gradient_config.warmup_window)

        smoothed_value * (1 - sample_weight) + sample_value * sample_weight
      else
        gradient_config.recency_bias_factor *
          sample_value +
          (1 - gradient_config.recency_bias_factor) *
            smoothed_value
      end

    new_smoothed_value =
      if new_smoothed_value > sample_value * 2 do
        Math.clamp(new_smoothed_value * 0.95, min: 0, set: :integers)
      else
        Math.clamp(new_smoothed_value, min: 0, set: :integers)
      end

    # TODO: If we are a factor of 2 shy on inflight then
    # we could leave it alone, or even shrink it more dramatically...
    # how much will it shrink on its own, in that case?
    # TODO: Add to configuration, with docs
    # value_deviation_tolerance = 1.5

    # Basically: draw a line between the two points, then walk a certain amount
    # along that line towards the new value based on the `recency_bias_factor`.
    # Clamping the gradient reduces the impact of outlier sample values.
    gradient = Math.clamp(new_smoothed_value / sample_value, min: 0.5, max: 1.0)
    # TODO: Make this dynamic, or optionally dynamic based on an input "signal"
    queue_size = 2

    new_estimated_limit = gradient * gradient_config.estimated_concurrency_limit + queue_size

    new_estimated_limit =
      gradient_config.estimated_concurrency_limit * (1 - gradient_config.recency_bias_factor) +
        new_estimated_limit * gradient_config.recency_bias_factor

    # Floats are not worth dealing with. If we leave a touch of throughput on
    # the table by rounding down a float, we can just call that "head room"
    new_estimated_limit =
      Math.clamp(new_estimated_limit,
        min: gradient_config.min_concurrency_limit,
        max: gradient_config.max_concurrency_limit,
        set: :integers
      )

    {%{
       gradient_config
       | smoothed_value: new_smoothed_value,
         estimated_concurrency_limit: new_estimated_limit
     }, new_estimated_limit}
  end
end
