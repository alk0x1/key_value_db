defmodule DesafioCli do
  def main(_args) do
    loop(%{})
  end

  defp loop(state) do
    IO.write("> ")

    input = case IO.gets("") do
      :eof -> :eof
      input -> String.trim(input)
    end

    case input do
      "quit" ->
        IO.puts("Terminating session")
        :ok

      :eof ->
        IO.puts("Terminating session")
        :ok

      _ ->
        new_state = Command.process(input, state)
        loop(new_state)
    end
  end
end
