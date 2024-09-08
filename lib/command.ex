defmodule Command do
  alias Persistence, as: P

  def process("BEGIN", state) do
    new_state = State.push_context(state)
    IO.puts("OK")
    new_state
  end

  def process("COMMIT", state) do
    case length(state.stack) do
      1 ->
        IO.puts("ERR \"No transaction\"")
        state

      _ ->
        # Merge the current context into the previous one
        new_state = State.merge_context(state)
        IO.puts("OK")

        # If there's only one map left in the stack, persist the change
        if length(new_state.stack) == 1 do
          P.compact_log(new_state)
        end

        new_state
    end
  end

  def process("ROLLBACK", state) do
    case length(state.stack) do
      1 ->
        IO.puts("ERR \"No transaction\"")
        state

      _ ->
        new_state = State.pop_context(state)
        IO.puts("OK")
        new_state
    end
  end

  def process(input, state) do
    case String.split(input) do
      ["SET", key, value] ->
        new_state = State.set(state, key, Utils.parse_value(value))
        IO.puts("OK")

        # Log only if modifying the first map in the stack (no active transactions)
        if length(new_state.stack) == 1 do
          P.log_change({key, Utils.parse_value(value)})
        end

        new_state

      ["GET", key] ->
        case State.get(state, key) do
          nil -> IO.puts("NIL")
          value -> IO.puts(inspect(value))
        end
        state

      ["LIST"] ->
        Utils.print_stack(state)
        state

      _ ->
        IO.puts("ERR \"Invalid command\"")
        state
    end
  end
end
