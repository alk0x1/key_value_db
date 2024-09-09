defmodule SnapshotManager do
  @file_path "state.bin"
  @tmp_file_path "state.tmp"
  @log_file "state.log"

  def save_snapshot(%{stack: [first_map | _]}) do
    binary = :erlang.term_to_binary(first_map)

    File.write!(@tmp_file_path, binary)
    File.rename(@tmp_file_path, @file_path)
  end

  def load_snapshot do
    case File.read(@file_path) do
      {:ok, binary} ->
        first_map = :erlang.binary_to_term(binary)
        first_map
      {:error, :enoent} -> %{}
    end
  end

  def compact_log(%{stack: [_first_map | _]} = state) do
    save_snapshot(state)
    File.rm(@log_file)
  end
end
