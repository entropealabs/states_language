defmodule StatesLanguage.AST.Parallel do
  @moduledoc false
  @behaviour StatesLanguage.AST
  alias StatesLanguage.AST.{Await, Resource}
  alias StatesLanguage.Node

  @impl true
  def create(
        %Resource{
          name: state_name,
          node: %Node{
            parameters: parameters,
            input_path: input_path,
            branches: branches
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
          parameters = get_parameters(data, unquote(input_path), unquote(parameters))
          me = self()

          tasks =
            unquote(branches)
            |> Enum.with_index()
            |> Enum.map(fn {name, i} ->
              {:ok, pid} = name.start({me, parameters})
              pid
            end)

          debug("Starting parallel tasks: #{inspect(tasks)}")
          {:keep_state, %StatesLanguage{sl | _tasks: tasks}}
        end
      end
      | [Await.create(data)]
    ]
  end
end
