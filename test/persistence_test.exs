defmodule PersistenceTest do
  use ExUnit.Case, async: false

  @state_file "state.bin"
  @log_file "state.log"

  setup do
    File.rm_rf!(@state_file)
    File.rm_rf!(@log_file)
    :ok
  end

  test "save and load full map" do
    test_map = %{stack: [%{"a" => 1, "b" => 2}]}

    SnapshotManager.save_snapshot(test_map)
    assert File.exists?(@state_file)

    loaded_map = SnapshotManager.load_snapshot()
    assert loaded_map == %{"a" => 1, "b" => 2}
  end

  test "log changes and replay the log" do
    initial_map = %{}

    LogManager.append_to_log({"a", 123})
    LogManager.append_to_log({"b", 456})
    LogManager.append_to_log({"a", 789})

    assert File.exists?(@log_file)

    # Replay the log and reconstruct the state
    final_map = LogManager.replay_log(initial_map)
    assert final_map == %{"a" => 789, "b" => 456}
  end

  test "log replay should not affect an existing map" do
    existing_map = %{"a" => 111, "c" => 999}

    LogManager.append_to_log({"a", 123})
    LogManager.append_to_log({"b", 456})

    updated_map = LogManager.replay_log(existing_map)

    assert updated_map == %{"a" => 123, "b" => 456, "c" => 999}
  end

  test "compact log and ensure state is saved" do
    state = %{stack: [%{"a" => 123, "b" => 456}]}

    LogManager.append_to_log({"a", 789})
    LogManager.append_to_log({"b", 321})

    # Compact the log (this saves the current state and resets the log)
    SnapshotManager.compact_log(state)

    assert File.exists?(@state_file)

    loaded_map = SnapshotManager.load_snapshot()
    assert loaded_map == %{"a" => 123, "b" => 456}

    refute File.exists?(@log_file)
  end

  test "compaction preserves the latest state and clears the log" do
    state = %{stack: [%{"x" => 999}]}

    LogManager.append_to_log({"x", 111})
    LogManager.append_to_log({"y", 222})

    # Replay the log and validate the state before compaction
    intermediate_map = LogManager.replay_log(%{})
    assert intermediate_map == %{"x" => 111, "y" => 222}

    SnapshotManager.compact_log(state)

    # Ensure the state file is created with the correct snapshot
    loaded_map = SnapshotManager.load_snapshot()
    assert loaded_map == %{"x" => 999}  # Snapshot should match the original state

    # Replay the log after compaction (log should be empty now)
    replayed_map_after_compaction = LogManager.replay_log(%{})
    assert replayed_map_after_compaction == %{}
  end
end
