defmodule CommandTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    Application.put_env(:your_app, :test_mode, true)

    on_exit(fn ->
      File.rm_rf("test_state.bin")
      File.rm_rf("test_state.log")
      File.rm_rf("test_state.tmp")
      Application.put_env(:your_app, :test_mode, false)
    end)

    %{state: %{stack: [%{}]}}
  end

  test "BEGIN command", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("BEGIN", state)
      assert length(new_state.stack) == 2
    end)
    assert output == "1\n"
  end

  test "COMMIT command with transaction", %{state: _state} do
    state_with_transaction = %{stack: [%{}, %{"key" => "value"}]}
    output = capture_io(fn ->
      new_state = CommandRouter.process("COMMIT", state_with_transaction)
      assert length(new_state.stack) == 1
      assert new_state.stack == [%{"key" => "value"}]
    end)
    assert output == "0\n"
  end

  test "COMMIT command without transaction", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("COMMIT", state)
      assert new_state == state
    end)
    assert output == "ERR \"No transaction\"\n"
  end

  test "ROLLBACK command without transaction", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("ROLLBACK", state)
      assert new_state == state
    end)
    assert output == "ERR \"No transaction\"\n"
  end

  test "SET command", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("SET key value", state)
      assert new_state.stack == [%{"key" => "value"}]
    end)
    assert output == "FALSE value\n"
  end

  test "SET command with quoted key and value", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("SET 'quoted key' \"quoted value\"", state)
      assert new_state.stack == [%{"quoted key" => "quoted value"}]
    end)
    assert output == "FALSE quoted value\n"
  end

  test "SET command with integer value", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("SET key 12345", state)
      assert new_state.stack == [%{"key" => 12345}]
    end)
    assert output == "FALSE 12345\n"
  end

  test "SET command with boolean value TRUE", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("SET key TRUE", state)
      assert new_state.stack == [%{"key" => true}]
    end)
    assert output == "FALSE true\n"
  end

  test "SET command with boolean value FALSE", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("SET key FALSE", state)
      assert new_state.stack == [%{"key" => false}]
    end)
    assert output == "FALSE false\n"
  end

  test "SET command with invalid syntax (too few arguments)", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("SET key", state)
      assert new_state == state
    end)
    assert output == "ERR \"SET <key> <value> - Syntax error\"\n"
  end

  test "SET command with invalid syntax (too many arguments)", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("SET key value extra", state)
      assert new_state == state
    end)
    assert output == "ERR \"SET <key> <value> - Syntax error\"\n"
  end

  test "GET command with existing key", %{state: state} do
    state = %{state | stack: [%{"key" => "value"}]}
    output = capture_io(fn ->
      new_state = CommandRouter.process("GET key", state)
      assert new_state == state
    end)
    assert output == "value\n"
  end

  test "GET command with non-existing key", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("GET nonexistent", state)
      assert new_state == state
    end)
    assert output == "NIL\n"
  end

  test "GET command with quoted key", %{state: state} do
    state = %{state | stack: [%{"quoted key" => "value"}]}
    output = capture_io(fn ->
      new_state = CommandRouter.process("GET 'quoted key'", state)
      assert new_state == state
    end)
    assert output == "value\n"
  end

  test "Invalid command", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("INVALID", state)
      assert new_state == state
    end)
    assert output == "ERR \"No command INVALID\"\n"
  end

  test "SET command logs change in-memory", %{state: state} do
    output = capture_io(fn ->
      new_state = CommandRouter.process("SET key value", state)
      assert new_state.stack == [%{"key" => "value"}]

      log_data = File.read!(FilePathManager.get_file_path("state.log"))
      log_entries = LogManager.extract_log_entries(log_data)
      assert log_entries == [["key", "value"]]
    end)

    assert output == "FALSE value\n"
  end

  test "COMMIT command simulates persistence in-memory" do
    state_with_transaction = %{stack: [%{}, %{"key" => "value"}]}

    output = capture_io(fn ->
      new_state = CommandRouter.process("COMMIT", state_with_transaction)
      assert length(new_state.stack) == 1
      assert new_state.stack == [%{"key" => "value"}]

      persisted_state = SnapshotManager.load_snapshot()

      assert persisted_state == %{"key" => "value"}
    end)

    assert output == "0\n"
  end
end
