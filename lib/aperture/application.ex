defmodule Aperture.Application do
  @moduledoc """
  Top-level `Supervisor`, whose only purpose is to supervise the `DynamicSupervisor`
  whose children are the `Aperture.Iris` processes started on-demand by calls to
  `Aperture.new/2`.
  """
  use Application

  def start(_, _) do
    children = [
      {DynamicSupervisor, name: Aperture.Irises, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Aperture.Supervisor)
  end
end
