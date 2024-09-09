defmodule LogManager do
  @log_file "state.log"
  @separator "\n"

  def append_to_log({key, value}) do
    log_entry = :erlang.term_to_binary([key, value])
    File.write!(@log_file, log_entry <> @separator, [:append])
  end

  def replay_log(map) do
    case File.read(@log_file) do
      {:ok, log_data} ->
        log_entries = extract_log_entries(log_data)
        Enum.reduce(log_entries, map, fn [key, value], acc ->
          Map.put(acc, key, value)
        end)
      {:error, :enoent} -> map
    end
  end

  def extract_log_entries(log_data) do
    log_data
    |> String.split(@separator, trim: true)
    |> Enum.map(& :erlang.binary_to_term/1)
  end
end
