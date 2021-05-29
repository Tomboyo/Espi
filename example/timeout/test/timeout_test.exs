defmodule TimeoutTest do
  use ExUnit.Case
  doctest Timeout

  test "greets the world" do
    assert Timeout.hello() == :world
  end
end
