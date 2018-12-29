defmodule DienerHansBotTest do
  use ExUnit.Case
  doctest DienerHansBot

  test "greets the world" do
    assert DienerHansBot.hello() == :world
  end
end
