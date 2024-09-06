defmodule Command do
  def process(input, state) do
    case String.split(input) do
      ["SET", key, value] ->
        new_state = State.set(state, key, Utils.parse_value(value))
        IO.puts("OK")
        new_state

      ["GET", key] ->
        case State.get(state, key) do
          nil -> IO.puts("NIL")
          value -> IO.puts(inspect(value))
        end
        state

      _ ->
        IO.puts("ERR \"Invalid command\"")
        state
    end
  end
end
