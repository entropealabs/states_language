defmodule StatesLanguage.AST.Enter do
  @moduledoc false
  @behaviour StatesLanguage.AST
  alias StatesLanguage.Edge

  @impl true
  def create(%Edge{source: source, target: target}) do
    quote location: :keep do
      @impl true
      def handle_event(
            :enter,
            unquote(source) = source,
            unquote(target) = target,
            data
          ) do
        debug("left #{inspect(source)} --> #{inspect(target)}: #{inspect(data)}")

        {:ok, data, actions} = handle_enter(source, target, data)

        :telemetry.execute([:states_language, :state_transition], %{}, %{
          source: source,
          target: target,
          data: data
        })

        {:keep_state, data, actions}
      end
    end
  end
end
