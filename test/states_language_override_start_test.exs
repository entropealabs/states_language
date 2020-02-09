defmodule StatesLanguageOverrideStartTest do
  use ExUnit.Case, async: true
  require Logger
  alias VendingMachine.Data

  setup do
    data = %Data{test: self(), keypad: %{input: "a123"}, lookup: %{result: %{candy: "Snickers"}}}
    {:ok, client_pid} = VendingMachine.start_link(data, start: "DispenseNosh")

    [client_pid: client_pid]
  end

  test "client goes through all states" do
    refute_receive %{event: :input_received}
    refute_receive :success
    assert_receive :finished, 1000
  end
end
