defmodule StatesLanguage.AST.Await do
  @moduledoc false
  @behaviour StatesLanguage.AST
  alias StatesLanguage.AST.Resource
  alias StatesLanguage.Node

  @impl true
  def create(%Resource{
        name: state_name,
        node: %Node{
          resource_path: resource_path,
          output_path: output_path,
          event: event,
          is_end: is_end
        }
      }) do
    quote location: :keep do
      @impl true
      def handle_event(
            :internal,
            :await_parallel_tasks,
            unquote(state_name) = state,
            %StatesLanguage{_tasks: tasks, data: data} = sl
          ) do
        debug("Checking tasks: #{inspect(tasks)}")

        if Enum.all?(tasks, fn
             {pid, res} -> true
             _ -> false
           end) do
          res = Enum.map(tasks, fn {_p, res} -> res end)
          data = put_result(res, unquote(resource_path), unquote(output_path), data)

          case AST.do_stop?(unquote(is_end)) do
            true ->
              :stop

            false ->
              {:keep_state, %StatesLanguage{sl | data: data, _tasks: []},
               [{:next_event, :internal, unquote(event)}]}
          end
        else
          debug("Waiting for more parallel results")
          {:keep_state, sl}
        end
      end

      @impl true
      def handle_event(
            :info,
            {:task_processed, result, pid},
            unquote(state_name),
            %StatesLanguage{_tasks: tasks} = sl
          ) do
        debug("Got Result: #{inspect(pid)} #{inspect(tasks)}")

        tasks =
          Enum.map(tasks, fn
            {pid, res} = d -> d
            ^pid = p -> {p, result}
            o -> o
          end)

        {:keep_state, %StatesLanguage{sl | _tasks: tasks},
         [{:next_event, :internal, :await_parallel_tasks}]}
      end
    end
  end
end
