defmodule Aperture.Lens do
  @moduledoc false
  # TODO: How to track updating custom signals? just additional entries somewhere?
  # or do those go in the MultiBuffer?
  # Keeps track of everything that we _can see_ in the system at present.
  # Used by processes internal to `Aperture` to track the number of inflight/concurrent operations
  # for a particular `Aperture.Iris` process tree, and to store the estimated concurrency limit
  # for whatever resource that process tree is related to.

  # Uses `ets` for atomic counters with write-concurrency, as well as efficient reads
  # for many calling processes.

  @doc """
  Creates a new concurrency tracking table, and returns the name of the table.

  ## Options

  * `:root_name` (Required) - The root name used for this process tree, usually assigned through a call to `Aperture.new/2`.
  * `:initial_concurrency_limit` - Max number of inflight operations that will be allowed for the resource regulated by this process tree. Defaults to `5`.
  """
  def new(opts) do
    table_name = name(Access.fetch!(opts, :root_name))

    _table = :ets.new(table_name,
      [
        :named_table,
        :set,
        # Need _any_ process to be able to write to the table, so that
        # we can avoid bottlenecks when Aperture has many callers across
        # many processes
        :public,
        {:read_concurrency, false},
        # Recommended in OTP > 25 for most use cases
        {:write_concurrency, :auto},
        {:decentralized_counters, true}
      ]
    )

    :ets.insert(table_name, {:estimated_concurrency_limit, opts[:initial_concurrency_limit] || 5})
    :ets.insert(table_name, {:inflight, 0})

    table_name
  end

  def get_estimated_concurrency_limit(root_name) do
    :ets.lookup_element(name(root_name), :estimated_concurrency_limit, 2)
  end

  def set_estimated_concurrency_limit(root_name, estimated_limit) do
    :ets.update_element(name(root_name), :estimated_concurrency_limit, {2, estimated_limit})

    :ok
  end

  @doc """
  Records that a new operation for the resource has just started.

  ***Must*** be balanced by a call to `sub_inflight_op/1` when the operation
  has completed.
  """
  def add_inflight_op(root_name) do
    :ets.update_counter(name(root_name), :inflight, {2, 1})
  end

  @doc """
  Records that an operation for the resource has completed, successfully or not.
  """
  def sub_inflight_op(root_name) do
    :ets.update_counter(name(root_name), :inflight, {2, -1, 0, 0}, {:inflight, 0})
  end

  def get_inflight_op_count(root_name) do
    :ets.lookup_element(name(root_name), :inflight, 2)
  end
  
  def name(root_name) do
    :"Aperture-#{root_name}-Lens"
  end
end
