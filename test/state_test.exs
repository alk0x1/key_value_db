defmodule StateTest do
  use ExUnit.Case

  alias State

  test "initializes with a single empty map" do
    state = State.init()
    assert length(state.stack) == 1
    assert hd(state.stack) == %{}
  end

  test "sets and gets a value in the context" do
    state = State.init()
    state = State.set(state, "foo", 10)
    assert State.get(state, "foo") == 10
  end

  test "push_context adds a new context" do
    state = State.init()
    state = State.push_context(state)
    assert length(state.stack) == 2
  end

  test "pop_context removes the last context" do
    state = State.init()
    state = State.push_context(state)
    state = State.pop_context(state)
    assert length(state.stack) == 1
  end

  test "merge_context merges the top context with the previous" do
    state = State.init()
    state = State.set(state, "foo", 10)

    state = State.push_context(state)
    state = State.set(state, "bar", 20)

    state = State.merge_context(state)
    assert length(state.stack) == 1
    assert State.get(state, "foo") == 10
    assert State.get(state, "bar") == 20
  end
end
