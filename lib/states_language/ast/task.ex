defmodule StatesLanguage.AST.Task do
  @moduledoc false
  @behaviour StatesLanguage.AST
  alias StatesLanguage.AST.Resource
  alias StatesLanguage.Node

  @impl true
  def create(%Resource{
        name: state_name,
        node: %Node{
          resource: resource,
          parameters: parameters,
          input_path: input_path,
          resource_path: resource_path,
          output_path: output_path,
          is_end: is_end
        }
      }) do
    quote location: :keep do
      @impl true
      def handle_event(
            :internal,
            :handle_resource,
            unquote(state_name) = state,
            %StatesLanguage{data: data} = sl
          ) do
        parameters = get_parameters(data, unquote(input_path), unquote(parameters))

        {:ok, %StatesLanguage{data: data}, actions} =
          handle_resource(unquote(resource), parameters, state, sl)

        data = put_result(data, unquote(resource_path), unquote(output_path), parameters)

        case AST.do_stop?(unquote(is_end)) do
          true ->
            :stop

          false ->
            {:keep_state, %StatesLanguage{sl | data: data}, actions}
        end
      end
    end
  end
end
