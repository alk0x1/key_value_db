defmodule Utils do
  def parse_value(value) do
    case Integer.parse(value) do
      {num, _} -> num
      _ -> value
    end
  end

  def print_stack(state) do
    IO.puts("Current state stack:")

    Enum.with_index(state.stack, fn map, index ->
      IO.puts("Layer #{index + 1}: #{inspect(map)}")
    end)

    IO.puts("End of stack\n")
  end

end
