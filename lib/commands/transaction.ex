defmodule Commands.Transaction do
  alias State
  alias SnapshotManager

  def process("BEGIN", state) do
    update_state_stack(:push, state)
  end

  def process("COMMIT", state) do
    if length(state.stack) == 1 do
      IO.puts("ERR \"No transaction\"")
      state
    else
      update_state_stack(:merge, state)
    end
  end

  def process("ROLLBACK", state) do
    if length(state.stack) == 1 do
      IO.puts("ERR \"No transaction\"")
      state
    else
      update_state_stack(:pop, state)
    end
  end

  defp update_state_stack(action, state) do
    new_state = case action do
      :push -> State.push_context(state)
      :merge -> State.merge_context(state)
      :pop -> State.pop_context(state)
    end

    IO.puts(length(new_state.stack) - 1)

    if action == :merge and length(new_state.stack) == 1 do
      SnapshotManager.save_snapshot(new_state)
    end

    new_state
  end
end
