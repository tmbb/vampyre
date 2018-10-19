defmodule VampyreTest do
  use ExUnit.Case
  doctest Vampyre

  test "greets the world" do
    assert Vampyre.hello() == :world
  end
end
