defmodule StatesLanguageChoiceTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.TestClientChoice

  setup do
    {:ok, client_pid} =
      TestClientChoice.start_link(%{
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

  test "client handles choice" do
    assert_receive {"DoStart", %{}, "Start", %{}}, 1000

    assert_receive {:choice, 1}, 1000

    assert_receive {"DoThird", %{}, "ThirdState", %{}}, 1000

    assert_receive :finished, 1000
  end
end
