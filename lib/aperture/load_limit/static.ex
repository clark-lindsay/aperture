defmodule Aperture.LoadLimit.Static do
  @moduledoc """
  Fixed concurrency limit. Not recommended for most use cases, except in combination with other limits.
  """
  @behaviour Aperture.LoadLimit

  @doc """
  ## Options

  * `:concurrency_limit` (Required) - Statically defined limit
  """
  @impl true
  def new(opts), do: {Map.new(opts), Access.fetch!(opts, :concurrency_limit)}

  @impl true
  def update(static_config, _current_concurrency_limit, _window) do
    {static_config, static_config.concurrency_limit}
  end
end
