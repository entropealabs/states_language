defmodule StatesLanguageCastTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.TestClientCast

  setup do
    {:ok, client_pid} =
      TestClientCast.start_link(%{
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

  test "client goes through all states", %{client_pid: pid} do
    assert_receive {"DoStart", %{}, "Start", %{}}, 1000

    :ok = TestClientCast.cast(pid, :casting)

    assert_receive {"DoSecond", %{"isState" => true, "test" => "ok"}, "SecondState",
                    %{state: true}},
                   1000

    assert_receive {"DoThird", %{"thisIsDeep" => true, "exists" => true, "stringsOk" => "ok"},
                    "ThirdState", %{state: true}},
                   1000

    assert_receive {"DoFinish", %{}, "Finish", %{}}, 1000
  end
end
