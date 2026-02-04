defmodule Aperture.Application do
  @moduledoc """
  Top-level `Supervisor`, whose only purpose is to supervise the `DynamicSupervisor`
  whose children are the `Aperture.Iris` processes started on-demand by calls to
  `Aperture.new/2`.
  """
  use Application

  @impl Application
  def start(_, _) do
    # TODO: Does the name here need to be _globally_ unique, and should therefore
    # take in or use an "instance name" and/or allow for `:via` tuples?
    children = [
      {DynamicSupervisor, name: Aperture.Irises, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Aperture.Supervisor)
  end
end
