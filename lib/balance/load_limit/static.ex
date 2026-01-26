defmodule Balance.LoadLimit.Static do
  @moduledoc """
  Fixed concurrency limit. Not recommended for most use cases.

  ## Options

  * `:concurrency_limit` (Required) - Statically defined limit
  """
  @behaviour Balance.LoadLimit

  @impl true
  def new(opts), do: {Map.new(opts), Access.fetch!(opts, :concurrency_limit)}

  @impl true
  def update(static_config, _current_limit, _window) do
    {static_config, static_config.concurrency_limit}
  end
end
