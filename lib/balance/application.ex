defmodule Balance.Application do
  @moduledoc """
  Top-level `Supervisor`, whose only purpose is to supervise the `DynamicSupervisor`
  whose children are the `Balance.Scale` processes started on-demand by calls to
  `Balance.new/2`.
  """
  use Application

  def start(_, _) do
    children = [
      {DynamicSupervisor, name: Balance.Scales, strategy: :one_for_one}
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Balance.Supervisor)
  end
end
