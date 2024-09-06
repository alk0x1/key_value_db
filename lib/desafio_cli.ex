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
        process_command(input, state)
    end
  end

  defp process_command(input, state) do
    case String.split(input) do
      ["SET", key, value] ->
        new_state = Map.put(state, key, parse_value(value))
        IO.puts("OK")
        loop(new_state)

      ["GET", key] ->
        case Map.get(state, key) do
          nil -> IO.puts("NIL")
          value -> IO.puts(inspect(value))
        end
        loop(state)

      _ ->
        IO.puts("ERR \"Invalid command\"")
        loop(state)
    end
  end

  defp parse_value(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end
end
