defmodule CommandRouter do
  alias Commands.{Transaction, DataManipulation}

  def process("BEGIN" = command, state), do: Transaction.process(command, state)
  def process("COMMIT" = command, state), do: Transaction.process(command, state)
  def process("ROLLBACK" = command, state), do: Transaction.process(command, state)

  def process(command, state) do
    case String.split(command) do
      ["SET" | args] -> DataManipulation.process(["SET" | args], state)
      ["GET" | args] -> DataManipulation.process(["GET" | args], state)
      ["LIST"] -> DataManipulation.process("LIST", state)

      [unknown_command | _rest] ->
        IO.puts("ERR \"No command #{unknown_command}\"")
        state

      _ ->
        IO.puts("ERR \"Invalid command\"")
        state
    end
  end
end
