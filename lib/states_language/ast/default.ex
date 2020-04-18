# credo:disable-for-this-file
defmodule StatesLanguage.AST.Default do
  @moduledoc false
  @behaviour StatesLanguage.AST

  @impl true
  def create(_) do
    quote location: :keep do
      defdelegate call(pid, event), to: :gen_statem
      defdelegate call(pid, event, timeout), to: :gen_statem

      defdelegate cast(pid, event), to: :gen_statem

      @impl true
      def handle_resource(_, _, _, data), do: {:ok, data, []}

      @impl true
      def handle_call(_, from, _, data), do: {:ok, data, {:reply, from, :ok}}

      @impl true
      def handle_cast(_, _, data), do: {:ok, data, []}

      @impl true
      def handle_info(_, _, data), do: {:ok, data, []}

      @impl true
      def handle_transition(_, _, data), do: {:ok, data, []}

      @impl true
      def handle_enter(_, _, data), do: {:ok, data, []}

      @impl true
      def handle_termination(_, _, data), do: :ok

      @impl true
      def handle_generic_timeout(_, _, data), do: {:ok, data, []}

      @impl true
      def handle_state_timeout(_, _, data), do: {:ok, data, []}

      @impl true
      def handle_event_timeout(_, _, data), do: {:ok, data, []}

      defoverridable handle_resource: 4,
                     handle_call: 4,
                     handle_cast: 3,
                     handle_info: 3,
                     handle_transition: 3,
                     handle_enter: 3,
                     handle_termination: 3,
                     handle_generic_timeout: 3,
                     handle_state_timeout: 3,
                     handle_event_timeout: 3

      @impl true
      def handle_event(:internal, na_event, na_state, %StatesLanguage{} = data) do
        Logger.warn("Unknown Event #{inspect(na_event)} while in state #{inspect(na_state)}")
        :keep_state_and_data
      end

      @impl true
      def handle_event(:enter, source, target, %StatesLanguage{} = data) do
        Logger.warn("Unknown enter event from #{inspect(source)} to #{inspect(target)}")
        :keep_state_and_data
      end

      @impl true
      def handle_event(:info, event, state, %StatesLanguage{} = data) do
        {:ok, data, actions} = handle_info(event, state, data)

        Logger.debug(
          "Handled info event: #{inspect(event)} in state #{state} with data #{inspect(data)}"
        )

        {:keep_state, data, actions}
      end

      @impl true
      def handle_event({:call, from}, event, state, %StatesLanguage{} = data) do
        {:ok, data, actions} = handle_call(event, from, state, data)

        Logger.debug(
          "Handled call event: #{inspect(event)} in state #{state} with data #{inspect(data)}"
        )

        {:keep_state, data, actions}
      end

      @impl true
      def handle_event(:cast, event, state, %StatesLanguage{} = data) do
        {:ok, data, actions} = handle_cast(event, state, data)

        Logger.debug(
          "Handled cast event: #{inspect(event)} in state #{state} with data #{inspect(data)}"
        )

        {:keep_state, data, actions}
      end

      @impl true
      def handle_event({:timeout, :generic}, event, state, %StatesLanguage{} = data) do
        {:ok, data, actions} = handle_generic_timeout(event, state, data)

        Logger.debug(
          "Handled generic timeout event: #{inspect(event)} in state #{state} with data #{
            inspect(data)
          }"
        )

        {:keep_state, data, actions}
      end

      @impl true
      def handle_event(:state_timeout, event, state, %StatesLanguage{} = data) do
        {:ok, data, actions} = handle_state_timeout(event, state, data)

        Logger.debug(
          "Handled state timeout event: #{inspect(event)} in state #{state} with data #{
            inspect(data)
          }"
        )

        {:keep_state, data, actions}
      end

      @impl true
      def handle_event(:timeout, event, state, %StatesLanguage{} = data) do
        {:ok, data, actions} = handle_event_timeout(event, state, data)

        Logger.debug(
          "Handled event timeout event: #{inspect(event)} in state #{state} with data #{
            inspect(data)
          }"
        )

        {:keep_state, data, actions}
      end
    end
  end
end
