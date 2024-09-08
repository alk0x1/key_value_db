defmodule Commands.DataManipulation do
  alias State
  alias Persistence, as: P
  alias Utils

  def process(["SET", key, value], state) do
    new_state = State.set(state, key, Utils.parse_value(value))
    IO.puts("OK")

    if length(new_state.stack) == 1 do
      P.log_change({key, Utils.parse_value(value)})
    end

    new_state
  end

  def process(["GET", key], state) do
    case State.get(state, key) do
      nil -> IO.puts("NIL")
      value -> IO.puts(inspect(value))
    end

    state
  end

  def process("LIST", state) do
    Utils.print_stack(state)
    state
  end

  def process(["SET" | _], state), do: handle_invalid_set(state)
  def process(["GET" | _], state), do: handle_invalid_get(state)

  defp handle_invalid_set(state) do
    IO.puts("ERR \"SET <key> <value> - Syntax error\"")
    state
  end

  defp handle_invalid_get(state) do
    IO.puts("ERR \"GET <key> - Syntax error\"")
    state
  end
end
