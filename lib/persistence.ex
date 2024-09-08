defmodule Persistence do
  @file_path "state.bin"      # Compacted state file (snapshot)
  @tmp_file_path "state.tmp"  # Temp file for atomic operations
  @log_file "state.log"       # Log file to record all changes

  def save_full_map(%{stack: [first_map | _]}) do
    {:ok, binary} = Msgpax.pack(first_map)

    # Write the snapshot (compacted) state to a temp file, then rename
    File.write!(@tmp_file_path, binary)
    File.rename(@tmp_file_path, @file_path)
  end

  def load_full_map do
    case File.read(@file_path) do
      {:ok, binary} ->
        {:ok, first_map} = Msgpax.unpack(binary)
        first_map

      {:error, :enoent} ->
        %{}
    end
  end

  # Append incremental changes to the log file (serialize as a list)
  def log_change({key, value}) do
    log_entry = Msgpax.pack!([key, value])
    File.write!(@log_file, log_entry, [:append])
  end

  # Replay the log to rebuild the map state from the log entries
  def replay_log(map) do
    case File.read(@log_file) do
      {:ok, log_data} ->
        log_entries = extract_log_entries(log_data)

        Enum.reduce(log_entries, map, fn [key, value], acc ->
          Map.put(acc, key, value)
        end)

      {:error, :enoent} ->
        map
    end
  end

  def extract_log_entries(binary_data) do
    do_extract_log_entries(binary_data, [])
  end

  def do_extract_log_entries("", acc), do: Enum.reverse(acc)

  def do_extract_log_entries(binary_data, acc) do
    # Unpack one log entry from the start of the binay
    {log_entry, rest} = Msgpax.unpack_slice!(binary_data)
    do_extract_log_entries(rest, [log_entry | acc])
  end

  def compact_log(%{stack: [_first_map | _]} = state) do
    save_full_map(state)
    File.rm(@log_file)
  end
end
