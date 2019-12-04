# Map and JSONPath

This guide will walk us through using the [Map](https://states-language.net/spec.html#map-state) type and JSONPath support to concurrently transform a list of objects to our desired output format.

Let's start with our incoming JSON.

## JSON Payload

```json
{
  "client": "test_client",
  "agency": "test_agency",
  "detail": {
    "items": [
      {
        "description": "Item 1",
        "amount": "$124.65",
        "service": "$3.00",
        "name": "This is item 1"
      },
      {
        "description": "Item 2",
        "amount": "$124.65",
        "service": "$3.00",
        "name": "This is item 1"
      }
    ]
  }
}
```

Now, let's say we want to transform each of our `detail.items` to something that looks like this.

```json
{
  "desc": "Item 1",
  "amnt": 12465,
  "service_fee": 300,
  "title": "This is item 1"
}
```

We'll first start by configuring our state machine to pass the items to a child state machine to handle the transformations.

## test/support/states_language_test_mutation.json

```json
{
  "Comment": "Test map mutations",
  "StartAt": "MapMutation",
  "States": {
    "MapMutation": {
      "Type": "Map",
      "InputPath": "$.detail",
      "ItemsPath": "$.items",
      "Iterator": "StatesLanguage.TestClientItem",
      "ResourcePath": "$.line_items",
      "Next": "Output"
    },
    "Output": {
      "Type": "Task",
      "Resource": "DoOutput",
      "End": true
    }
  }
}
```

Here you can see we're telling our interpeter to go into the `detail` object and that our `Items` to iterate over are within `detail.items`. 

Next we tell the interpeter that we want to use the `StatesLanguage.TestClientItem` state machine as our `Iterator`, meaning for each item in our `ItemsPath`, we will start a new process from the module `StatesLanguage.TestClientItem`.

We'll gather these results and put them into our data at `line_items`. This way we maintain our original input.

Once all processes have finished, we'll move on to our `Output` state, which in this case will just log our results.

Ok, let's have a look at our module for this state machine.

## test/support/test_client_mutation.ex

```elixir
defmodule StatesLanguage.TestClientMutation do
  @external_resource "test/support/states_language_test_mutation.json"

  use StatesLanguage, data: "test/support/states_language_test_mutation.json"

  require Logger

  @impl true
  def handle_resource("DoOutput", _, "Output", sl) do
    Logger.info("Line Items: #{inspect(get_in(sl.data, ["line_items"]))}")
    {:ok, sl, []}
  end

  @impl true
  def handle_termination(_, _, %StatesLanguage{} = sl) do
    items = get_in(sl.data, ["line_items"])
    send(sl.data.test, {:line_items, items})
    :ok
  end
end
```

We don't have to do much here, as most of the work is going to be done by our `Iterator` module.

We handle our `DoOutput` resource, and because this is also a test fixture, we'll send a message back to our test process letting it know the results as well.

Ok, on to our `Iterator` module. First, let's look at our JSON for the state machine.

## test/support/test_client_item.json

```json
{
  "Comment": "Mutate TestClient Items",
  "StartAt": "Mutate",
  "States": {
    "Mutate": {
      "Type": "Task",
      "Resource": "DoMutate",
      "Parameters": {
        "desc.$": "$.description",
        "amnt.$": "$.amount",
        "service_fee.$": "$.service",
        "title.$": "$.name"
      },
      "End": true
    }
  }
}
```

Here we can see some of the cool things we can do with the JSONPath support and `Parameters`.

Any key that ends with ".$" within our `Parameters` block, tells the interpeter that the value is going to be a JSONPath, and to use the key before the ".$" as the key name. This allows us to transform our incoming data to a totally new format.

Now this is pretty cool, but we also wanted to transform our monetary amounts into integers. The original data has all monetary values as strings prepended with the "$" sign, and a "." separating dollars and cents. So we'll need to write some code to make that happen.

Let's see our iterator module to see how to handle that.

## test/support/test_client_item.ex

```elixir
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
```

You can see we're pattern matching on the updated keys for our params. The "Map" type is unique in that it receives a single item as it's `params` argument after having the `Parameters` block applied to it's values.

So we convert our monetary strings to integers and send the individual result back to our parent state machine. "Parallel" and "Map" types listen for a special message of type `t:StatesLanguage.task_processed/0`. You may wonder why we also have to return the pid of ourselves, this is to ensure our results are in the same order as the original list of items. Which is a requirement of the StatesLanguage spec.

If you've checked out the [StatesLanguage](https://github.com/citybaseinc/states_language) locally you can run this by running `$ mix test test/json_mutation_test.exs`

Hopefully this gives a good background on using the "Map" type and JSONPath support.
