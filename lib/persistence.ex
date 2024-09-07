defmodule Persistence do
  @file_path "state.bin"
  @tmp_file_path "state.tmp"

  def save_first_map(%{stack: [first_map | _]}) do
    {:ok, binary} = Msgpax.pack(first_map)

    File.write!(@tmp_file_path, binary)

    File.rename(@tmp_file_path, @file_path)
  end

  def load_first_map do
    case File.read(@file_path) do
      {:ok, binary} ->
        {:ok, first_map} = Msgpax.unpack(binary)
        first_map
      {:error, :enoent} ->
        %{}
    end
  end
end
