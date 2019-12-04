defmodule StatesLanguage.TestClientChoice do
  @external_resource "test/support/states_language_test_choice.json"

  use StatesLanguage, data: "test/support/states_language_test_choice.json"

  @impl true
  def handle_resource("DoFinish", _, "Finish", data) do
    {:ok, data, []}
  end

  @impl true
  def handle_resource("DoSecond", _, "SecondState", data) do
    {:ok, data, [{:next_event, :internal, {:digit, 1}}]}
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
  def handle_transition({:digit, 1}, "SecondState", %StatesLanguage{data: data} = sl) do
    send(data.test, {:choice, 1})
    {:ok, sl, []}
  end

  @impl true
  def handle_transition({:digit, 2}, "SecondState", %StatesLanguage{data: data} = sl) do
    send(data.test, {:choice, 2})
    {:ok, sl, []}
  end

  @impl true
  def handle_transition(_, _, data), do: {:ok, data, []}

  @impl true
  def handle_termination(_, _, data) do
    send(data.data.test, :finished)
    :ok
  end
end
