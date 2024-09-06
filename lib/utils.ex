defmodule Utils do
  def parse_value(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end
end
