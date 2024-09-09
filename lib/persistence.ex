defmodule Persistence do
  @file_path "state.bin"      # Compacted state file (snapshot)
  @tmp_file_path "state.tmp"  # Temp file for atomic operations
  @log_file "state.log"       # Log file to record all changes
  @separator "\n"

  def save_full_map(%{stack: [first_map | _]}) do
    binary = :erlang.term_to_binary(first_map)

    File.write!(@tmp_file_path, binary)
    File.rename(@tmp_file_path, @file_path)
  end

  def load_full_map do
    case File.read(@file_path) do
      {:ok, binary} ->
        first_map = :erlang.binary_to_term(binary)
        first_map

      {:error, :enoent} ->
        %{}
    end
  end

  # Append incremental changes to the log file (serialize as a list)
  def log_change({key, value}) do
    log_entry = :erlang.term_to_binary([key, value])
    File.write!(@log_file, log_entry <> @separator, [:append])
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

  def extract_log_entries(log_data) do
    log_data
    |> String.split(@separator, trim: true)
    |> Enum.map(& :erlang.binary_to_term/1)
  end

  def compact_log(%{stack: [_first_map | _]} = state) do
    save_full_map(state)
    File.rm(@log_file)
  end
end
