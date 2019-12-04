defmodule StatesLanguageVendingMachineTest do
  use ExUnit.Case, async: true
  require Logger
  alias VendingMachine.Data

  setup do
    {:ok, client_pid} = VendingMachine.start_link(%Data{test: self()})

    [client_pid: client_pid]
  end

  test "client goes through all states" do
    assert_receive :finished, 1000
  end
end
