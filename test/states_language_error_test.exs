defmodule StatesLanguageErrorTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.TestClientError

  setup do
    {:ok, client_pid} =
      TestClientError.start_link(%{
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

  test "client starts in start state", %{client_pid: pid} do
    Logger.info("Client is started with pid #{inspect(pid)}")
    assert_receive {"DoStart", %{}, "Start", %{}}, 1000
  end

  test "client catches and handles error" do
    assert_receive {"DoStart", %{}, "Start", %{}}, 1000

    assert_receive {"DoHandleError", %{"isState" => true, "test" => "ok"}, "HandleError", data},
                   1000

    assert_receive :finished, 1000
  end
end
