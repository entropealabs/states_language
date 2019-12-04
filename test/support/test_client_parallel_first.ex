defmodule StatesLanguage.TestClientParallel.First do
  @external_resource "test/support/parallel_first.json"

  use StatesLanguage, data: "test/support/parallel_first.json"
  require Logger

  @impl true
  def handle_resource(
        "ParallelResource",
        _params,
        "ParallelFirst",
        %StatesLanguage{} = sl
      ) do
    send(sl._parent_data.test, {:parallel_first, 10})
    {:ok, %StatesLanguage{sl | data: %{result: 124}}, []}
  end

  @impl true
  def handle_resource(resource, params, current_state, %StatesLanguage{data: data} = sl) do
    debug(
      "Handling resource #{resource} with params #{inspect(params)} in state #{current_state} with data #{
        inspect(data)
      }"
    )

    send(sl._parent_data.test, {resource, params, current_state, data})
    {:ok, sl, {:next_event, :internal, :transition}}
  end

  @impl true
  def handle_termination(_, _, %StatesLanguage{data: data} = sl) do
    debug("Sending Parent Result #{inspect(data)} from #{inspect(self())}")
    send(sl._parent, {:task_processed, data, self()})
    :ok
  end
end
