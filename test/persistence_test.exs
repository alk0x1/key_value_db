defmodule PersistenceTest do
  use ExUnit.Case, async: false

  setup do
    Application.put_env(:your_app, :test_mode, true)

    # Cleanup before each test
    on_exit(fn ->
      File.rm_rf(FilePathManager.get_file_path("state.bin"))
      File.rm_rf(FilePathManager.get_file_path("state.log"))
      File.rm_rf(FilePathManager.get_file_path("state.tmp"))
      Application.put_env(:your_app, :test_mode, false)
    end)

    {:ok, %{state: %{stack: [%{}]}}}
  end

  test "save and load full map" do
    test_map = %{stack: [%{"a" => 1, "b" => 2}]}

    SnapshotManager.save_snapshot(test_map)
    assert File.exists?(FilePathManager.get_file_path("state.bin"))

    loaded_map = SnapshotManager.load_snapshot()
    assert loaded_map == %{"a" => 1, "b" => 2}
  end

  test "log changes and replay the log" do
    initial_map = %{}

    LogManager.append_to_log({"a", 123})
    LogManager.append_to_log({"b", 456})
    LogManager.append_to_log({"a", 789})

    assert File.exists?(FilePathManager.get_file_path("state.log"))

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

    SnapshotManager.compact_log(state)

    assert File.exists?(FilePathManager.get_file_path("state.bin"))
    loaded_map = SnapshotManager.load_snapshot()
    assert loaded_map == %{"a" => 123, "b" => 456}

    refute File.exists?(FilePathManager.get_file_path("state.log"))
  end

  test "compaction preserves the latest state and clears the log" do
    state = %{stack: [%{"x" => 999}]}

    LogManager.append_to_log({"x", 111})
    LogManager.append_to_log({"y", 222})

    intermediate_map = LogManager.replay_log(%{})
    assert intermediate_map == %{"x" => 111, "y" => 222}

    SnapshotManager.compact_log(state)

    loaded_map = SnapshotManager.load_snapshot()
    assert loaded_map == %{"x" => 999}

    replayed_map_after_compaction = LogManager.replay_log(%{})
    assert replayed_map_after_compaction == %{}
  end

  test "merge tmp file with bin when tmp exists" do
    initial_state = %{stack: [%{"a" => 1}]}
    SnapshotManager.save_snapshot(initial_state)

    corrupted_state = %{stack: [%{"a" => 1, "b" => 2}]}
    binary = :erlang.term_to_binary(corrupted_state)
    File.write!(FilePathManager.get_file_path("state.tmp"), binary)

    loaded_map = SnapshotManager.load_snapshot()
    assert loaded_map == %{stack: [%{"a" => 1, "b" => 2}]}

    assert File.rm(FilePathManager.get_file_path("state.tmp")) == :ok
    refute File.exists?(FilePathManager.get_file_path("state.tmp"))
  end

  test "tmp file with corrupted data is ignored" do
    initial_state = %{stack: [%{"a" => 1}]}
    SnapshotManager.save_snapshot(initial_state)

    File.write!(FilePathManager.get_file_path("state.tmp"), <<1, 2, 3, 4>>)

    loaded_map = SnapshotManager.load_snapshot()
    assert loaded_map == %{"a" => 1}

    assert File.rm(FilePathManager.get_file_path("state.tmp")) == :ok
    refute File.exists?(FilePathManager.get_file_path("state.tmp"))
  end

  test "no .bin file but valid .tmp file is loaded" do
    state_from_tmp = %{stack: [%{"a" => 10, "b" => 20}]}
    binary = :erlang.term_to_binary(state_from_tmp)
    File.write!(FilePathManager.get_file_path("state.tmp"), binary)

    loaded_map = SnapshotManager.load_snapshot()

    assert loaded_map == %{stack: [%{"a" => 10, "b" => 20}]}

    assert File.rm(FilePathManager.get_file_path("state.tmp")) == :ok
    refute File.exists?(FilePathManager.get_file_path("state.tmp"))
  end
end
