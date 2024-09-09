defmodule Utils do
  def parse_value(value) do
    case value do
      "TRUE" -> true
      "FALSE" -> false
      "NIL" -> nil
      _ ->
        cond do
          String.match?(value, ~r/^\d+$/) -> String.to_integer(value)
          # String with double quotes (handles escaping)
          String.starts_with?(value, "\"") and String.ends_with?(value, "\"") ->
            String.slice(value, 1..-2//1) |> String.replace("\\\"", "\"")
          # String with single quotes (for keys with spaces or special characters)
          String.starts_with?(value, "'") and String.ends_with?(value, "'") ->
            String.slice(value, 1..-2//1) |> String.replace("\\'", "'")
          true -> value
        end
    end
  end

  def print_stack(state) do
    IO.puts("Current state stack:")

    Enum.with_index(state.stack, fn map, index ->
      IO.puts("Layer #{length(state.stack) - index - 1}: #{inspect(map)}")
    end)

    IO.puts("End of stack\n")
  end
end
