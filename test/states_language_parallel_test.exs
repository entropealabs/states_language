defmodule StatesLanguageParallelTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.TestClientParallel

  setup do
    {:ok, client_pid} =
      TestClientParallel.start_link(%{
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

  test "client goes through all states and runs parallel state machines" do
    assert_receive {"DoStart", %{}, "Start", %{}}, 1000

    assert_receive {:parallel_first, 10}, 1000
    assert_receive {:parallel_first, 10}, 1000

    assert_receive {"DoThird", %{"thisIsDeep" => true, "exists" => true, "stringsOk" => "ok"},
                    "ThirdState", %{state: true}},
                   1000

    assert_receive :finished, 1000
  end
end
