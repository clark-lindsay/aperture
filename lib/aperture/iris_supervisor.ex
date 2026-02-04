defmodule Aperture.IrisSupervisor do
  use Supervisor

  def start_link(init_args) do
    root_name = Access.fetch!(init_args, :root_name)

    Supervisor.start_link(__MODULE__, init_args, name: iris_supervisor_name(root_name))
  end

  @impl Supervisor
  def init(args) do
    # TODO: Should I wrap the ETS tables with GenServers?
    # What do I want to happen if/when things crash?

    _lens_table_name = Aperture.Lens.new(Access.fetch!(args, :root_name))


    children = [
      {Iris, args},
      # TODO: Add monitor process to listen for `:DOWN` messages
      # and decrement concurrency count accordingly
      {MultiBuffer, args}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def iris_supervisor_name(root_name) do
    :"Aperture-#{root_name}-Supervisor"
  end

  def multi_buffer_process_name(root_name) do
    :"Aperture-#{root_name}-MultiBuffer"
  end

  def iris_process_name(root_name) do
    :"Aperture-#{root_name}-Iris"
  end
end
