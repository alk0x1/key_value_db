defmodule DesafioCli do
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
        new_state = Command.process(input, state)
        loop(new_state)
    end
  end

  defp get_input do
    case IO.gets("> ") do
      {:error, reason} -> {:error, reason}
      input when is_binary(input) -> String.trim(input)
    end
  end

  defp load_state do
    if File.exists?("state.bin") do
      IO.puts("Loading state from disk...")
      initial_map = Persistence.load_first_map()
      %{stack: [initial_map]}
    else
      IO.puts("No saved state found, initializing new state...")
      State.init()
    end
  end
end
