defmodule Aperture.Iris do
  use GenServer

  alias Aperture.IrisSupervisor

  def start_link(opts) do
    root_name = Access.fetch!(opts, :root_name)

    opts = put_in(opts, [:name], IrisSupervisor.iris_process_name(root_name))

    GenServer.start_link(__MODULE__, opts)
  end

  @impl GenServer
  def init(init_args) do
    schedule_tick()

    {:ok, Map.new(init_args)}
  end

  @impl GenServer
  def handle_info(:tick, state) do
    # TODO: read in data from the buffer, and calculate a new limit
    # based on the limit config
  end

  defp schedule_tick(after_ms \\ 1_000) do
    Process.send_after(self(), :tick, after_ms)
  end
end
