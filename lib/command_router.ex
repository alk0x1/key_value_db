defmodule CommandRouter do
  alias Commands.{Transaction, DataManipulation}

  def process("BEGIN" <> _rest, state), do: Transaction.process("BEGIN", state)
  def process("COMMIT" <> _rest, state), do: Transaction.process("COMMIT", state)
  def process("ROLLBACK" <> _rest, state), do: Transaction.process("ROLLBACK", state)

  def process(command, state) do
    case String.split(command) do
      ["SET" | args] -> DataManipulation.process(["SET" | args], state)
      ["GET" | args] -> DataManipulation.process(["GET" | args], state)
      ["LIST"] -> DataManipulation.process(["LIST"], state)

      [unknown_command | _rest] ->
        IO.puts("ERR \"No command #{unknown_command}\"")
        state

      _ ->
        IO.puts("ERR \"Invalid command\"")
        state
    end
  end
end
