defmodule PersistenceTest do
  use ExUnit.Case

  alias Persistence

  setup do
    state = %{stack: [%{"key1" => "value1", "key2" => "value2"}]}

    if File.exists?("state.bin"), do: File.rm!("state.bin")
    if File.exists?("state.tmp"), do: File.rm!("state.tmp")

    {:ok, state: state}
  end

  test "saves the first map in the stack to a .tmp file and renames it atomically", %{state: state} do
    Persistence.save_first_map(state)

    refute File.exists?("state.tmp")

    assert File.exists?("state.bin")

    {:ok, content} = File.read("state.bin")
    assert byte_size(content) > 0
  end

  test "loads the first map from the binary file", %{state: state} do
    Persistence.save_first_map(state)

    first_map = Persistence.load_first_map()

    assert first_map == %{"key1" => "value1", "key2" => "value2"}
  end
end
