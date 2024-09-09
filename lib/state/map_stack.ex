defmodule State do
  def init do
    %{stack: [%{}]}
  end

  def set(state, key, value) do
    [current | rest] = state.stack
    new_current = Map.put(current, key, value)
    %{state | stack: [new_current | rest]}
  end

  def get(state, key) do
    [current_map | _] = state[:stack]
    Map.get(current_map, key)
  end

  def push_context(state) do
    %{state | stack: [%{} | state.stack]}
  end

  def pop_context(state) do
    [_ | rest] = state.stack
    %{state | stack: rest}
  end

  def merge_context(state) do
    [current, previous | rest] = state.stack
    new_previous = Map.merge(previous, current)
    %{state | stack: [new_previous | rest]}
  rescue
    MatchError -> raise "Cannot merge context: there must be at least two contexts in the stack"
  end
end
