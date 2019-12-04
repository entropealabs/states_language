defmodule StatesLanguage.TestClientWait do
  @external_resource "test/support/states_language_test_wait.json"

  use StatesLanguage, data: "test/support/states_language_test_wait.json"

  @impl true
  def handle_resource("DoFinish", _params, "Finish", %StatesLanguage{data: data} = sl) do
    send(data.test, :finished)
    {:ok, sl, []}
  end
end
