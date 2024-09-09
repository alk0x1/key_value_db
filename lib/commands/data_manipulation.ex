defmodule Commands.DataManipulation do
  alias State
  alias LogManager

  def process(["SET" | args], state) do
    case split_input_args(args) do
      [key, value] ->
        parsed_key = parse_value(key)
        parsed_value = parse_value(value)

        updated_state = update_stack(state, parsed_key, parsed_value)

        print_result(state, parsed_key, parsed_value)

        updated_state

      _ ->
        IO.puts(~s(ERR "SET <key> <value> - Syntax error"))
        state
    end
  end

 def process(["GET" | args], state) do
    case split_input_args(args) do
      [key] ->
        parsed_key = parse_value(key)

        case lookup_key_in_stack(parsed_key, state.stack) do
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

  defp split_input_args(args) do
    args
    |> Enum.join(" ")
    |> tokenize()
  end

  defp tokenize(string) do
    regex = ~r/'[^']*'|"[^"]*"|\S+/
    Regex.scan(regex, string)
    |> Enum.map(fn [token] -> String.trim(token, ~s('")) end)
  end

  defp lookup_key_in_stack(_key, []), do: nil

  defp lookup_key_in_stack(key, [layer | rest]) do
    case Map.get(layer, key) do
      nil -> lookup_key_in_stack(key, rest)
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

  defp update_stack(state, key, value) do

    new_state = Map.update!(state, :stack, fn stack ->
      [Map.put(List.first(stack), key, value) | List.delete_at(stack, 0)]
    end)

    if length(new_state.stack) == 1 do
      LogManager.append_to_log({key, value})
    end

    new_state
  end

  defp print_result(state, key, value) do
    [current_state | _] = state.stack
    IO.puts("#{if Map.has_key?(current_state, key), do: "TRUE", else: "FALSE"} #{value}")
  end
end
