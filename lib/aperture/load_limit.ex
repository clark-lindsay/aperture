defmodule Aperture.LoadLimit do
  @moduledoc """
  Provides a behaviour for defining limit algorithms
  """

  # TODO: I think that this makes more sense as a protocol, not as a behaviour
  @doc """
  Creates a new `Aperture.LoadLimit` configuration, whose properties are specific to the algorithm.
  """
  @callback new(term()) :: {term(), initial_concurrency_limit :: pos_integer()}

  @doc """
  Calculates a new `Aperture.LoadLimit` configuration based on an existing one,
  the current concurrency limit, and the most recent `Aperture.Window`. Must
  return the limit configuration with the new concurrency limit in a tuple.
  """
  @callback update(
              limit_config :: term(),
              current_concurrency_limit :: pos_integer(),
              Aperture.Window.t()
            ) :: {limit_config :: term(), pos_integer()}
end
