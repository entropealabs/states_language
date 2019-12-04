defmodule JSONMutationTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.TestClientMutation

  @json %{
    "client" => "test_client",
    "agency" => "test_agency",
    "detail" => %{
      "items" => [
        %{
          "description" => "Item 1",
          "amount" => "$124.65",
          "service" => "$3.00",
          "name" => "This is item 1"
        },
        %{
          "description" => "Item 2",
          "amount" => "$124.65",
          "service" => "$3.00",
          "name" => "This is item 1"
        }
      ]
    }
  }

  setup do
    json = Map.put(@json, :test, self())
    {:ok, _client_pid} = TestClientMutation.start_link(json)
    :ok
  end

  test "map results" do
    assert_receive {:line_items, items}
  end
end
