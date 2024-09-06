defmodule DesafioCliTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "SET command stores a key-value pair" do
    output = capture_io([input: "SET foo 123\nquit\n"], fn ->
      DesafioCli.main([])
    end)

    assert output =~ "> OK\n> Terminating session\n"
  end

  test "GET command retrieves the value for a given key" do
    output = capture_io([input: "SET foo 123\nGET foo\nquit\n"], fn ->
      DesafioCli.main([])
    end)

    assert output =~ "> OK\n> 123\n> Terminating session\n"
  end

  test "GET returns NIL for non-existent key" do
    output = capture_io([input: "GET bar\nquit\n"], fn ->
      DesafioCli.main([])
    end)

    assert output =~ "> NIL\n> Terminating session\n"
  end
end
