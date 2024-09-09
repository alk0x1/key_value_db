defmodule StateManager do
  @log_file "state.log"
  @bin_file "state.bin"
  @max_log_size 5

  alias LogManager
  alias SnapshotManager
  alias State

  # Load the state from binary snapshot and log file
  def load_state do
    state_bin_exists = File.exists?(@bin_file)
    log_exists = File.exists?(@log_file)

    cond do
      state_bin_exists && log_exists ->
        IO.puts("Loading state from state.bin...")
        initial_map = SnapshotManager.load_snapshot()
        IO.puts("Replaying log for latest changes...")
        updated_map = LogManager.replay_log(initial_map)
        %{stack: [updated_map]}

      state_bin_exists ->
        IO.puts("Loading state from state.bin...")
        initial_map = SnapshotManager.load_snapshot()
        %{stack: [initial_map]}

      true ->
        IO.puts("No saved state found, initializing new state...")
        State.init()
    end
  end

  def maybe_save_snapshot(state) do
    if log_size() >= @max_log_size do
      IO.puts("Saving Snapshot...")
      SnapshotManager.compact_log(state)
    end
  end

  defp log_size do
    case File.stat(@log_file) do
      {:ok, stat} -> stat.size
      {:error, _} -> 0
    end
  end
end
