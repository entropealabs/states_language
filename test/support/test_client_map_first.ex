defmodule StatesLanguage.TestClientMap.First do
  @external_resource "test/support/map_first.json"

  use StatesLanguage, data: "test/support/map_first.json"
  require Logger

  @impl true
  def handle_resource("MapResource", item, "MapFirst", %StatesLanguage{data: _data} = sl) do
    item = %{item | data: item.data + 10}
    send(sl._parent_data.test, {:map, item.data})
    sl = %StatesLanguage{sl | data: item}
    {:ok, sl, [{:next_event, :internal, :transition}]}
  end

  @impl true
  def handle_resource(resource, item, current_state, %StatesLanguage{data: data} = sl) do
    debug(
      "Handling resource #{resource} with params #{inspect(item)} in state #{current_state} with data #{inspect(data)}"
    )

    send(sl._parent_data.test, {resource, item, current_state, data})
    {:ok, sl, {:next_event, :internal, :transition}}
  end

  @impl true
  def handle_termination(reason, state, %StatesLanguage{data: data} = sl) do
    debug(
      "Sending Parent Result in #{state} with reason #{reason} #{inspect(sl)} from #{inspect(self())}"
    )

    send(sl._parent, {:task_processed, data, self()})
    :ok
  end
end
