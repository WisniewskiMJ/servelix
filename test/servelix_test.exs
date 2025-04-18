defmodule ServelixTest do
  use ExUnit.Case
  doctest Servelix

  test "greets the world" do
    assert Servelix.hello() == :world
  end
end
