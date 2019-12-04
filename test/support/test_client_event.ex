defmodule StatesLanguage.TestClientEvent do
  @external_resource "test/support/states_language_test_event.json"

  use StatesLanguage, data: "test/support/states_language_test_event.json"

  @impl true
  def handle_resource("DoFinish", _, "Finish", data) do
    {:ok, data, []}
  end

  @impl true
  def handle_resource("DoStart", _, "Start", data) do
    {:ok, data, [{:next_event, :internal, {:success, true}}]}
  end

  @impl true
  def handle_resource("DoSecond", _, "SecondState", data) do
    {:ok, data, [{:next_event, :internal, {:second_success, true}}]}
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

  def handle_termination(_, _, data) do
    send(data.data.test, :finished)
    :ok
  end
end
