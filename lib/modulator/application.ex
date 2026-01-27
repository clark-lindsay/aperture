defmodule Modulator.Application do
  @moduledoc """
  Top-level `Supervisor`, whose only purpose is to supervise the `DynamicSupervisor`
  whose children are the `Modulator.Valve` processes started on-demand by calls to
  `Modulator.new/2`.
  """
  use Application

  def start(_, _) do
    children = [
      {DynamicSupervisor, name: Modulator.Valves, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Modulator.Supervisor)
  end
end
