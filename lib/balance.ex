defmodule Balance do
  @moduledoc """
  TODO
  Probably just pull from a READ_ME external source module attribute
  (if that's still the right way to do that)
  """

  def new(name, {load_limit_type, load_limit_config}) do
    DynamicSupervisor.start_child(
      Balance.Scales,
      {Balance.Scale,
       %{
         name: name,
         load_limiter: load_limit_type.new(load_limit_config)
       }}
    )
  end

  @spec check(name :: atom()) ::
          :ok | {:error, :scale_not_found} | {:overloaded, metadata :: map()}
  def check(_name) do
    # hit the registry and see if we recognize the resource
    # check the resource
    {:error, :scale_not_found}
  end
end
