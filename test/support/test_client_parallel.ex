defmodule StatesLanguage.TestClientParallel do
  @external_resource "test/support/states_language_test_parallel.json"

  use StatesLanguage, data: "test/support/states_language_test_parallel.json"

  @impl true
  def handle_resource("DoFinish", _params, "Finish", data) do
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
  def handle_termination(_, _, %StatesLanguage{data: data}) do
    send(data.test, :finished)
    :ok
  end
end
