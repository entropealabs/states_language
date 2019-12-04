defmodule StatesLanguage.TestClientItem do
  @external_resource "test/support/test_client_item.json"

  use StatesLanguage, data: "test/support/test_client_item.json"

  require Logger

  @impl true
  def handle_resource("DoMutate", %{"amnt" => a, "service_fee" => sf} = params, "Mutate", data) do
    params =
      params
      |> Map.put("amnt", convert_to_integer(a))
      |> Map.put("service_fee", convert_to_integer(sf))

    Logger.debug("New params: #{inspect(params)}")
    send(data._parent, {:task_processed, params, self()})
    {:ok, data, []}
  end

  defp convert_to_integer(amount) do
    amount
    |> String.replace("$", "")
    |> String.replace(".", "")
    |> String.to_integer()
  end
end
