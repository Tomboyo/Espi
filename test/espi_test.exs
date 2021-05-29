defmodule EspiTest do
  use ExUnit.Case
  doctest Espi

  test "greets the world" do
    assert Espi.hello() == :world
  end
end
