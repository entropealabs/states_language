defmodule StatesLanguage.TestClientMutation do
  @external_resource "test/support/states_language_test_mutation.json"

  use StatesLanguage, data: "test/support/states_language_test_mutation.json"

  require Logger

  @impl true
  def handle_resource("DoOutput", _, "Output", sl) do
    Logger.info("Line Items: #{inspect(get_in(sl.data, ["line_items"]))}")
    {:ok, sl, []}
  end

  @impl true
  def handle_termination(_, _, %StatesLanguage{} = sl) do
    debug("Terminating: #{inspect(sl.data)}")
    items = get_in(sl.data, ["line_items"])
    send(sl.data.test, {:line_items, items})
    :ok
  end
end
