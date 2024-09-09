defmodule Commands.DataManipulation do
  alias State
  alias Persistence, as: P
  alias Utils

  def process(["SET" | args], state) do
    case tokenize_args(args) do
      [key, value] ->
        parsed_key = Utils.parse_value(key)
        parsed_value = Utils.parse_value(value)

        new_state = Map.update!(state, :stack, fn stack ->
          [Map.put(List.first(stack), parsed_key, parsed_value) | List.delete_at(stack, 0)]
        end)

        if length(new_state.stack) == 1 do
          P.log_change({key, Utils.parse_value(value)})
        end

        IO.puts("OK")

        new_state

      _ ->
        IO.puts(~s(ERR "SET <key> <value> - Syntax error"))
        state
    end
  end

 def process(["GET" | args], state) do
    case tokenize_args(args) do
      [key] ->
        parsed_key = Utils.parse_value(key)

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
    Utils.print_stack(state)
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
end
