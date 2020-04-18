defmodule StatesLanguage.AST.Map do
  @moduledoc false
  @behaviour StatesLanguage.AST
  alias StatesLanguage.AST.{Await, Resource}
  alias StatesLanguage.Node

  @impl true
  def create(
        %Resource{
          name: state_name,
          node: %Node{
            iterator: iterator,
            items_path: items_path,
            parameters: parameters,
            input_path: input_path
          }
        } = data
      ) do
    [
      quote location: :keep do
        @impl true
        def handle_event(
              :internal,
              :handle_resource,
              unquote(state_name) = state,
              %StatesLanguage{data: data} = sl
            ) do
          mod = unquote(iterator)

          items =
            get_parameters(data, [unquote(input_path), unquote(items_path)], unquote(parameters))

          me = self()

          tasks =
            items
            |> Enum.map(fn item ->
              {:ok, pid} = mod.start({me, {item, data}})
              pid
            end)

          Logger.debug("Starting Map tasks: #{inspect(tasks)}")
          {:keep_state, %StatesLanguage{sl | _tasks: tasks}}
        end
      end
      | [Await.create(data)]
    ]
  end
end
