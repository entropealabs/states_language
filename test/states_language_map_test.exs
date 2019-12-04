defmodule StatesLanguageMapTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.TestClientMap

  setup do
    {:ok, client_pid} =
      TestClientMap.start_link(%{
        detail: %{
          items: [
            %{
              data: 1,
              owner: "Chris"
            },
            %{
              data: 2,
              ownder: "Alex"
            },
            %{
              data: 3,
              owner: "Gaby"
            },
            %{
              data: 4,
              owner: "Oliver"
            },
            %{
              data: 5,
              owner: "Finn"
            },
            %{
              data: 6,
              owner: "Xander"
            }
          ]
        },
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

    assert_receive {:map, 11}, 1000
    assert_receive {:map, 12}, 1000
    assert_receive {:map, 13}, 1000
    assert_receive {:map, 14}, 1000
    assert_receive {:map, 15}, 1000
    assert_receive {:map, 16}, 1000

    assert_receive {"DoThird", %{"thisIsDeep" => true, "exists" => true, "stringsOk" => "ok"},
                    "ThirdState", %{state: true}},
                   1000

    assert_receive :finished, 1000
  end
end
