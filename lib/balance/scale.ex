defmodule Balance.Scale do
  use GenServer

  @impl GenServer
  def init(_init_arg) do
    {:ok, %{}}
  end
end
