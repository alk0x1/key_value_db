defmodule SnapshotManager do
  # Save snapshot atomically by writing to .tmp and renaming
  def save_snapshot(%{stack: [first_map | _]}) do
    binary = :erlang.term_to_binary(first_map)
    tmp_file = FilePathManager.get_file_path("state.tmp")
    state_file = FilePathManager.get_file_path("state.bin")
    File.write!(tmp_file, binary)
    File.rename(tmp_file, state_file)
  end

  # Load snapshot, prioritizing the .tmp file if it exists, merging with .bin
  def load_snapshot do
    tmp_file = FilePathManager.get_file_path("state.tmp")
    state_file = FilePathManager.get_file_path("state.bin")
    tmp_exists = File.exists?(tmp_file)
    bin_exists = File.exists?(state_file)

    cond do
      tmp_exists and bin_exists ->
        IO.puts("Found both .tmp and .bin files, merging them...")
        case load_from_file(tmp_file) do
          {:ok, tmp_data} -> tmp_data
          {:error, _reason} -> load_fallback_bin(state_file)
        end

      tmp_exists ->
        IO.puts("Only .tmp file found, trying to load from it...")
        case load_from_file(tmp_file) do
          {:ok, tmp_data} ->
            IO.puts("Loaded .tmp file successfully.")
            tmp_data
          {:error, _reason} ->
            IO.puts("Failed to load .tmp file, initializing new state.")
            %{}
        end

      bin_exists -> load_fallback_bin(state_file)

      true ->
        IO.puts("No saved state found, initializing new state...")
        %{}
    end
  end

  defp load_from_file(file_path) do
    case File.read(file_path) do
      {:ok, binary} ->
        try do
          {:ok, :erlang.binary_to_term(binary)}
        rescue
          _ -> {:error, :corrupt}
        end
      error ->
        error
    end
  end

  defp load_fallback_bin(file_path) do
    case load_from_file(file_path) do
      {:ok, bin_data} -> bin_data
      {:error, _reason} -> %{}  # default to an empty state if corrupted
    end
  end

  def compact_log(%{stack: [_first_map | _]} = state) do
    save_snapshot(state)
    File.rm(FilePathManager.get_file_path("state.log"))
  end
end
