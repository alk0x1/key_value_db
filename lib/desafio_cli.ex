defmodule DesafioCli do
  def main(_args) do
    state = StateManager.load_state()
    loop(state)
  end

  defp loop(state) do
    case get_input() do
      {:error, reason} ->
        IO.puts("Error: #{reason}")
        :ok

      input ->
        new_state = CommandRouter.process(input, state)
        StateManager.maybe_save_snapshot(new_state)
        loop(new_state)
    end
  end

  def get_input do
    case IO.gets("> ") do
      {:error, reason} -> {:error, reason}
      input when is_binary(input) -> String.trim(input)
    end
  end
end
