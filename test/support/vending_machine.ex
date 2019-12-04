defmodule VendingMachine do
  @external_resource "test/support/vending_machine.json"
  use StatesLanguage, data: "test/support/vending_machine.json"

  defmodule Data do
    defstruct keypad: %{input: ""}, lookup: %{result: nil}, error: "", test: nil
  end

  @impl true
  def handle_resource("StartKeyPad", _params, "AcceptInput", %StatesLanguage{} = sl) do
    me = self()
    # Let's pretend someone is pushing keys
    Task.start(fn ->
      send(me, {:keypress, "a"})
      send(me, {:keypress, "1"})
      send(me, {:keypress, "2"})
      send(me, {:keypress, "3"})
    end)

    {:ok, sl, []}
  end

  @impl true
  def handle_resource(
        "DoLookup",
        %{"keyed_input" => code},
        "DoLookup",
        %StatesLanguage{data: %Data{} = data} = sl
      ) do
    debug("Looking up code #{code}")

    {data, actions} =
      case lookup(code) do
        {:ok, result} ->
          {%Data{data | lookup: %{result: result}}, [{:next_event, :internal, :success}]}

        {:error, :network} ->
          {data, [{:next_event, :internal, :network_error}]}

        {:error, :no_result} ->
          {data, [{:next_event, :internal, :lookup_error}]}
      end

    {:ok, %StatesLanguage{sl | data: data}, actions}
  end

  @impl true
  def handle_resource(
        <<"SetError:", error::binary>>,
        _params,
        _any_state,
        %StatesLanguage{data: %Data{} = data} = sl
      ) do
    {:ok, %StatesLanguage{sl | data: %Data{data | error: error}},
     [{:next_event, :internal, :transition}]}
  end

  @impl true
  def handle_resource(
        <<"DisplayText:", key::binary>>,
        _params,
        "ShowError",
        %StatesLanguage{data: %Data{} = data} = sl
      ) do
    key = String.to_existing_atom(key)
    text = Map.get(data, key)
    Logger.info("Displaying Text: #{text}")
    {:ok, sl, [{:next_event, :internal, :transition}]}
  end

  @impl true
  def handle_resource(
        "DispenseNosh",
        _params,
        "DispenseNosh",
        %StatesLanguage{data: %Data{} = data} = sl
      ) do
    Logger.info("Dispensing one #{inspect(data.lookup.result.candy)}")
    {:ok, sl, []}
  end

  @impl true
  def handle_info({:keypress, digit}, "AcceptInput", %StatesLanguage{data: %Data{} = data} = sl) do
    input = data.keypad.input
    input = input <> digit

    actions =
      if String.length(input) > 3 do
        [{:next_event, :internal, %{event: :input_received}}]
      else
        []
      end

    {:ok, %StatesLanguage{sl | data: %Data{data | keypad: %{input: input}}}, actions}
  end

  @impl true
  def handle_termination(_, _, %StatesLanguage{data: %Data{} = data}) do
    send(data.test, :finished)
    :ok
  end

  defp lookup(1_234_556), do: {:error, :no_result}
  defp lookup(11_111_111), do: {:error, :network}

  defp lookup(_code) do
    {:ok, %{candy: "Snickers"}}
  end
end
