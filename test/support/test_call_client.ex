defmodule StatesLanguage.TestClientCall do
  @external_resource "test/support/states_language_test_call.json"

  use StatesLanguage, data: "test/support/states_language_test_call.json"

  @impl true
  def handle_resource("DoStart", p, "Start", %StatesLanguage{data: data} = sl) do
    send(data.test, {"DoStart", p, "Start", data})
    {:ok, sl, []}
  end

  @impl true
  def handle_resource(resource, params, current_state, %StatesLanguage{data: data} = sl) do
    debug(
      "Handling resource #{resource} with params #{inspect(params)} in state #{current_state} with data #{
        inspect(data)
      }"
    )

    send(data.test, {resource, params, current_state, data})
    {:ok, sl, {:next_event, :internal, :transition}}
  end

  @impl true
  def handle_call(event, from, "Start", data) do
    debug("Handling call event #{inspect(event)} in Start state")
    {:ok, data, [{:reply, from, :call_handled}, {:next_event, :internal, :call_received}]}
  end
end
