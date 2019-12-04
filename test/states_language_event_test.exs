defmodule StatesLanguageEventTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.TestClientEvent

  setup do
    {:ok, client_pid} =
      TestClientEvent.start_link(%{
        state: true,
        test: self(),
        level2: %{
          "hmm" => "ok",
          yeah: "boom",
          another_level: %{
            ok: true
          }
        }
      })

    [client_pid: client_pid]
  end

  test "client can override transition event" do
    assert_receive {"DoThird", %{}, "ThirdState", %{}}, 1000

    assert_receive :finished, 1000
  end
end
