defmodule StatesLanguageWaitTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.TestClientWait

  setup do
    datetime =
      DateTime.utc_now()
      |> DateTime.add(300, :millisecond)
      |> DateTime.to_iso8601()

    {:ok, client_pid} =
      TestClientWait.start_link(%{
        seconds: 0.1345,
        timestamp: datetime,
        test: self()
      })

    [client_pid: client_pid]
  end

  test "client goes through all states" do
    assert_receive :finished, 10_000
  end
end
