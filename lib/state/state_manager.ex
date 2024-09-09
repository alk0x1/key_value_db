defmodule StateManager do
  @log_file "state.log"
  @bin_file "state.bin"
  @max_log_size 100

  alias LogManager
  alias SnapshotManager
  alias State

  def load_state do
    case {File.exists?(@bin_file), File.exists?(@log_file)} do
      {true, true} -> load_from_bin_and_log()
      {true, false} -> load_from_bin()
      {false, true} -> load_from_log()
      {false, false} -> load_new_state()
    end
  end

  def maybe_save_snapshot(state) do
    if log_size() >= @max_log_size do
      IO.puts("Saving Snapshot...")
      SnapshotManager.compact_log(state)
    end
  end

  defp load_from_bin_and_log do
    IO.puts("Loading state from state.bin...")
    initial_map = SnapshotManager.load_snapshot()
    IO.puts("Replaying log for latest changes...")
    updated_map = LogManager.replay_log(initial_map)
    %{stack: [updated_map]}
  end

  defp load_from_bin do
    IO.puts("Loading state from state.bin...")
    initial_map = SnapshotManager.load_snapshot()
    %{stack: [initial_map]}
  end

  defp load_from_log do
    IO.puts("Loading state from state.log...")
    map = LogManager.replay_log(%{})
    %{stack: [map]}
  end

  defp load_new_state do
    IO.puts("No saved state found, initializing new state...")
    State.init()
  end

  defp log_size do
    case File.stat(@log_file) do
      {:ok, %{size: size}} -> size
      {:error, _} -> 0
    end
  end
end
