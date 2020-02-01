defmodule StatesLanguage.Base do
  @moduledoc false
  defmacro __using__(start: start) do
    quote location: :keep do
      require Logger
      @behaviour :gen_statem
      @behaviour StatesLanguage

      import StatesLanguage.JSONPath,
        only: [get_parameters: 3, put_result: 4, run_json_path: 2]

      def child_spec(opts) do
        %{
          id: __MODULE__,
          start: {__MODULE__, :start_link, opts},
          restart: :transient
        }
      end

      defoverridable(child_spec: 1)

      @impl true
      def callback_mode, do: [:handle_event_function, :state_enter]

      def start_link(name, data, opts) do
        :gen_statem.start_link(
          name,
          __MODULE__,
          data,
          opts
        )
      end

      def start_link(data, opts) do
        :gen_statem.start_link(
          __MODULE__,
          data,
          opts
        )
      end

      def start_link(data) do
        :gen_statem.start_link(
          __MODULE__,
          data,
          []
        )
      end

      def start(name, data, opts) do
        :gen_statem.start(
          name,
          __MODULE__,
          data,
          opts
        )
      end

      def start(data, opts) do
        :gen_statem.start(
          __MODULE__,
          data,
          opts
        )
      end

      def start(data) do
        :gen_statem.start(
          __MODULE__,
          data,
          []
        )
      end

      @impl true
      def init({parent, data}) do
        debug("Nested Init: Parent - #{inspect(parent)} Data - #{inspect(data)}")

        {parent_data, child_data} =
          case data do
            {item, parent_data} -> {parent_data, item}
            _ -> {data, %{}}
          end

        do_init(unquote(start), parent, parent_data, child_data)
      end

      @impl true
      def init(data) do
        debug("Init: Data - #{inspect(data)}")
        do_init(unquote(start), nil, nil, data)
      end

      def do_init(start, parent, parent_data, data) do
        actions = [{:next_event, :internal, :handle_resource}]
        Process.flag(:trap_exit, true)

        {:ok, start,
         %StatesLanguage{
           _parent: parent,
           _parent_data: parent_data,
           data: data
         }, actions}
      end

      @impl true
      def terminate(reason, state, data) do
        debug("Terminating in state #{state} #{inspect(reason)}")

        :telemetry.execute([:states_language, :terminating], %{}, %{
          source: state,
          target: :terminating,
          data: data
        })

        handle_termination(reason, state, data)
      end

      defp debug(msg) do
        Logger.debug(fn -> "#{__MODULE__} - #{msg}" end)
      end
    end
  end
end
