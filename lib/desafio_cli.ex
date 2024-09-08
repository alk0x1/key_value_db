defmodule DesafioCli do
  @log_file "state.log"
  @bin_file "state.bin"
  @max_log_size 5 # threshold to trigger compaction based on log size

  def main(_args) do
    state = load_state()
    loop(state)
  end

  defp loop(state) do
    case get_input() do
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        :ok

      input ->
        new_state = CommandRouter.process(input, state)
        maybe_compact_log(new_state)  # Trigger log compaction if needed
        loop(new_state)
    end
  end

  def get_input do
    case IO.gets("> ") do
      {:error, reason} -> {:error, reason}
      input when is_binary(input) -> String.trim(input)
    end
  end

  def load_state do
    state_bin_exists = File.exists?(@bin_file)
    log_exists = File.exists?(@log_file)

    if state_bin_exists do
      IO.puts("Loading state from state.bin...")
      initial_map = Persistence.load_full_map()

      # If log exists, replay it over the state.bin data
      if log_exists do
        IO.puts("Replaying log for latest changes...")
        updated_map = Persistence.replay_log(initial_map)
        %{stack: [updated_map]}
      else
        %{stack: [initial_map]}
      end
    else
      IO.puts("No saved state found, initializing new state...")
      State.init()
    end
  end

  def maybe_compact_log(state) do
    if log_size() >= @max_log_size do
      IO.puts("Compacting log...")
      Persistence.compact_log(state)
    end
  end

  def log_size do
    case File.stat(@log_file) do
      {:ok, stat} -> stat.size
      {:error, _} -> 0
    end
  end
end
