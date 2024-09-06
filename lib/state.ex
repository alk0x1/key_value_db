defmodule State do
  def set(state, key, value) do
    Map.put(state, key, value)
  end

  def get(state, key) do
    Map.get(state, key)
  end
end
