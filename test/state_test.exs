defmodule StateTest do
  use ExUnit.Case

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

  test "get returns nil for non-existing key" do
    state = State.init()
    assert State.get(state, "non_existing_key") == nil
  end

  test "set overwrites existing value" do
    state = State.init()
    state = State.set(state, "foo", 10)
    state = State.set(state, "foo", 20)
    assert State.get(state, "foo") == 20
  end

  test "pop_context does not remove the last context" do
    state = State.init()
    state = State.pop_context(state)
    assert length(state.stack) == 0
  end

  test "merge_context raises an error when there is only one context" do
    state = State.init()
    assert_raise RuntimeError, "Cannot merge context: there must be at least two contexts in the stack", fn ->
      State.merge_context(state)
    end
  end
end
