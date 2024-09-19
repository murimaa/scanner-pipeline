defmodule DocumentPipelineTest do
  use ExUnit.Case
  doctest DocumentPipeline

  test "greets the world" do
    assert DocumentPipeline.hello() == :world
  end
end
