defmodule Commands.Transaction do
  alias State
  alias Persistence, as: P

  def process("BEGIN", state) do
    new_state = State.push_context(state)
    IO.puts(length(new_state.stack) - 1)
    new_state
  end

  def process("COMMIT", state) do
    case length(state.stack) do
      1 ->
        IO.puts("ERR \"No transaction\"")
        state

      _ ->
        new_state = State.merge_context(state)
        IO.puts(length(new_state.stack) - 1)

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
        IO.puts(length(new_state.stack) - 1)

        new_state
    end
  end
end
