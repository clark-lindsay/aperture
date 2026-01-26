defmodule Balance.LoadLimit do
  @moduledoc """
  Provides a behaviour for defining limit algorithms
  """

  @doc """
  Creates a new `Balance.LoadLimit` configuration, whose properties are specific to the algorithm.
  """
  @callback new(term()) :: {term(), initial_concurrency_limit :: pos_integer()}

  @doc """
  Calculates a new `Balance.LoadLimit` configuration based on an existing one,
  the current concurrency limit, and the most recent `Balance.Window`. Must
  return the limit configuration with the new concurrency limit in a tuple.
  """
  @callback update(
              limit_config :: term(),
              current_concurrency_limit :: pos_integer(),
              Balance.Window.t()
            ) :: {limit_config :: term(), pos_integer()}
end
