defmodule DesafioCli do
  def main(_args) do
    state = State.init()
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
end
