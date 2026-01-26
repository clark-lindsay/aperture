defmodule BalanceTest do
  use ExUnit.Case
  doctest Balance

  test "greets the world" do
    assert Balance.hello() == :world
  end
end
