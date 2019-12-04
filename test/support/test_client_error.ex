defmodule StatesLanguage.TestClientError do
  @external_resource "test/support/states_language_test_error.json"

  use StatesLanguage, data: "test/support/states_language_test_error.json"

  def handle_resource("DoStart", params, "Start", %StatesLanguage{data: data} = sl) do
    debug("Handling start Resource DoStart in Start state with params #{inspect(params)}")
    send(data.test, {"DoStart", params, "Start", data})
    {:ok, sl, [{:next_event, :internal, :error}]}
  end

  @impl true
  def handle_resource("DoFinish", _, "Finish", data) do
    {:ok, data, []}
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
  def handle_termination(_, _, data) do
    send(data.data.test, :finished)
    :ok
  end
end
