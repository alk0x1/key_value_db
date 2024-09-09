defmodule Commands.DataManipulation do
  alias State
  alias Persistence, as: P

  def process(["SET" | args], state) do
    case tokenize_args(args) do
      [key, value] ->
        parsed_key = parse_value(key)
        parsed_value = parse_value(value)

        updated_state = Map.update!(state, :stack, fn stack ->
          [Map.put(List.first(stack), parsed_key, parsed_value) | List.delete_at(stack, 0)]
        end)

        if length(updated_state.stack) == 1 do
          P.log_change({key, parse_value(value)})
        end

        # Only check if the key exist in the current state
        [current_state | _] = state.stack
        IO.puts("#{if Map.has_key?(current_state, parsed_key), do: "TRUE", else: "FALSE"} #{parsed_value}")

        updated_state

      _ ->
        IO.puts(~s(ERR "SET <key> <value> - Syntax error"))
        state
    end
  end

 def process(["GET" | args], state) do
    case tokenize_args(args) do
      [key] ->
        parsed_key = parse_value(key)

        case find_in_stack(parsed_key, state.stack) do
          nil -> IO.puts("NIL")
          value -> IO.puts("#{value}")
        end

        state

      _ ->
        IO.puts(~s(ERR "GET <key> - Syntax error"))
        state
    end
  end

  def process(["LIST"], state) do
    Enum.with_index(state.stack, fn map, index ->
      IO.puts("Layer #{length(state.stack) - index - 1}: #{inspect(map)}")
    end)

    state
  end

  defp tokenize_args(args) do
    args
    |> Enum.join(" ")
    |> tokenize()
  end

  defp tokenize(string) do
    regex = ~r/'[^']*'|"[^"]*"|\S+/
    Regex.scan(regex, string)
    |> Enum.map(fn [token] -> String.trim(token, ~s('")) end)
  end

  defp find_in_stack(_key, []), do: nil

  defp find_in_stack(key, [layer | rest]) do
    case Map.get(layer, key) do
      nil -> find_in_stack(key, rest)
      value -> value
    end
  end

  defp parse_value(value) do
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

end
