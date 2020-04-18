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
        {start, opts} = Keyword.pop(opts, :start)

        :gen_statem.start_link(
          name,
          __MODULE__,
          {data, start},
          opts
        )
      end

      def start_link(data, opts) do
        {start, opts} = Keyword.pop(opts, :start)

        :gen_statem.start_link(
          __MODULE__,
          {data, start},
          opts
        )
      end

      def start_link(data) do
        :gen_statem.start_link(
          __MODULE__,
          {data, nil},
          []
        )
      end

      def start(name, data, opts) do
        {start, opts} = Keyword.pop(opts, :start)

        :gen_statem.start(
          name,
          __MODULE__,
          {data, start},
          opts
        )
      end

      def start(data, opts) do
        {start, opts} = Keyword.pop(opts, :start)

        :gen_statem.start(
          __MODULE__,
          {data, start},
          opts
        )
      end

      def start(data) do
        :gen_statem.start(
          __MODULE__,
          {data, nil},
          []
        )
      end

      @impl true
      def init({{parent, data}, override_start}) do
        Logger.debug("Nested Init: Parent - #{inspect(parent)} Data - #{inspect(data)}")

        {parent_data, child_data} =
          case data do
            {item, parent_data} -> {parent_data, item}
            _ -> {data, %{}}
          end

        start = get_start_state(unquote(start), override_start)
        do_init(start, parent, parent_data, child_data)
      end

      @impl true
      def init({data, override_start}) do
        Logger.debug("Init: Data - #{inspect(data)}")
        start = get_start_state(unquote(start), override_start)
        do_init(start, nil, nil, data)
      end

      def get_start_state(start, nil), do: start

      def get_start_state(_start, override), do: override

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
        Logger.debug("Terminating in state #{state} #{inspect(reason)}")

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
