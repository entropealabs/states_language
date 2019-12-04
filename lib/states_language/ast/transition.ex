defmodule StatesLanguage.AST.Transition do
  @moduledoc false
  @behaviour StatesLanguage.AST
  alias StatesLanguage.Edge

  @impl true
  def create(%Edge{
        source: source,
        target: target,
        event: event
      }) do
    quote location: :keep do
      @impl true
      def handle_event(:info, unquote(event) = event, unquote(source) = state, data) do
        debug(
          "got info transition event #{inspect(event)} in state #{inspect(state)} transitioning to #{
            inspect(unquote(target))
          }"
        )

        {:ok, data, actions} = handle_transition(event, state, data)

        {:next_state, unquote(target), data,
         [{:next_event, :internal, :handle_resource} | actions]}
      end

      @impl true
      def handle_event(:internal, unquote(event) = event, unquote(source) = state, data) do
        debug(
          "got internal transition event #{inspect(event)} in state #{inspect(state)} transitioning to #{
            inspect(unquote(target))
          }"
        )

        {:ok, data, actions} = handle_transition(event, state, data)

        {:next_state, unquote(target), data,
         [{:next_event, :internal, :handle_resource} | actions]}
      end
    end
  end
end
