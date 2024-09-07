defmodule CommandTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    {:ok, state: %{stack: [%{}]}}
  end

  test "BEGIN command", %{state: state} do
    output = capture_io(fn ->
      new_state = Command.process("BEGIN", state)
      assert length(new_state.stack) == 2
    end)
    assert output == "OK\n"
  end

  test "COMMIT command with transaction", %{state: state} do
    state_with_transaction = %{stack: [%{}, %{"key" => "value"}]}
    output = capture_io(fn ->
      new_state = Command.process("COMMIT", state_with_transaction)
      assert length(new_state.stack) == 1
      assert new_state.stack == [%{"key" => "value"}]
    end)
    assert output == "OK\n"
  end

  test "COMMIT command without transaction", %{state: state} do
    output = capture_io(fn ->
      new_state = Command.process("COMMIT", state)
      assert new_state == state
    end)
    assert output == "ERR \"No transaction\"\n"
  end

  # test "ROLLBACK command with transaction" do
  #   state_with_transaction = %{stack: [%{}, %{"key" => "value"}]}
  #   output = capture_io(fn ->
  #     new_state = Command.process("ROLLBACK", state_with_transaction)
  #     assert length(new_state.stack) == 1
  #     assert new_state.stack == [%{}]
  #   end)
  #   assert output == "OK\n"
  # end

  test "ROLLBACK command without transaction", %{state: state} do
    output = capture_io(fn ->
      new_state = Command.process("ROLLBACK", state)
      assert new_state == state
    end)
    assert output == "ERR \"No transaction\"\n"
  end

  test "SET command", %{state: state} do
    output = capture_io(fn ->
      new_state = Command.process("SET key value", state)
      assert new_state.stack == [%{"key" => "value"}]
    end)
    assert output == "OK\n"
  end

  test "GET command with existing key", %{state: state} do
    state = %{state | stack: [%{"key" => "value"}]}
    output = capture_io(fn ->
      new_state = Command.process("GET key", state)
      assert new_state == state
    end)
    assert output == "\"value\"\n"
  end

  test "GET command with non-existing key", %{state: state} do
    output = capture_io(fn ->
      new_state = Command.process("GET nonexistent", state)
      assert new_state == state
    end)
    assert output == "NIL\n"
  end


  test "Invalid command", %{state: state} do
    output = capture_io(fn ->
      new_state = Command.process("INVALID", state)
      assert new_state == state
    end)
    assert output == "ERR \"Invalid command\"\n"
  end
end
