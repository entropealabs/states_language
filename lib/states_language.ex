defmodule StatesLanguage do
  @moduledoc """
  A macro to parse [StatesLanguage](https://states-language.net/spec.html) JSON and create :gen_statem modules
  """
  alias StatesLanguage.{AST, Graph, SchemaLoader}
  alias Xema.Validator
  require Logger

  @schema :states_language
          |> :code.priv_dir()
          |> Path.join("schemas/states_language.json")
          |> File.read!()
          |> Jason.decode!()
          |> JsonXema.new(loader: SchemaLoader)

  @typedoc """
  All callbacks are expected to return a tuple containing an updated (if necessary) `t:StatesLanguage.t/0`,
  and a list of actions to perform after the callback has exectuted.
  A default callback that doesn't need to do anything would just return {:ok, data, []}
  """
  @type callback_result :: {:ok, t(), [:gen_statem.action()] | :gen_statem.action() | []}

  @typedoc """
  When using the "Parallel" or "Map" types, the children processes must `send/2` a message to the parent process of this type. The `child_process` pid is the `t:pid/0` of the child spawned by the parent state machine, generally the same as calling `self/0` in the child process itself.
  """
  @type task_processed :: {:task_processed, result :: any(), child_process :: pid()}

  @doc """
  Called when a Choice or Task state is transitioned to.
  ## Arguments
  - resource: The value of the `Resource` field for this state
  - params: the data after applying any JSONPath selectors to our data attribute
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_resource(
              resource :: String.t(),
              params :: term(),
              state :: String.t(),
              data :: t()
            ) :: callback_result()

  @doc """
  Called when something has sent an event to our process.
  ## Arguments
  - event: the event that was sent to us
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_info(event :: term(), state :: String.t(), data :: t()) :: callback_result()

  @doc """
  Called when a transition event has been received, but before we transition to the next state.
  ## Arguments
  - event: The transition event received
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_transition(event :: term(), state :: String.t(), data :: t()) ::
              callback_result()

  @doc """
  Called when we enter a new state, but before any additional actions have occurred.
  ## Arguments
  - old_state: The previous state we were in
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_enter(old_state :: String.t(), state :: String.t(), data :: t()) ::
              callback_result()

  @doc """
  Called when a call event has been received. It is up to your implentation to return {:reply, from, result} to send the result back to the caller.
  ## Arguments
  - event: the payload sent with the call
  - from: used to reply to the caller
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_call(
              event :: term(),
              from :: GenServer.from(),
              state :: String.t(),
              data :: t()
            ) :: callback_result()

  @doc """
  Called when a cast event has been received.
  ## Arguments
  - event: the payload sent with the cast
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_cast(event :: term(), state :: String.t(), data :: t()) ::
              callback_result()

  @doc """
  Called when a process is ending. This can be because it was killed or a state indicated it's the end of the state machine. Used for cleanup.
  ## Arguments
  - reason: the reason we are ending eg; `:normal`, `:kill`, etc.
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_termination(reason :: term(), state :: String.t(), data :: t()) :: :ok

  @doc """
  Called when a [Generic Timeout](http://erlang.org/doc/man/gen_statem.html#type-generic_timeout) is triggered.
  ## Arguments
  - event: The event set for the timeout
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_generic_timeout(event :: term(), state :: String.t(), data :: t()) ::
              callback_result()

  @doc """
  Called when a [State Timeout](http://erlang.org/doc/man/gen_statem.html#type-state_timeout) is triggered.
  ## Arguments
  - event: The event set for the timeout
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_state_timeout(event :: term(), state :: String.t(), data :: t()) ::
              callback_result()

  @doc """
  Called when a [Event Timeout](http://erlang.org/doc/man/gen_statem.html#type-event_timeout) is triggered.
  ## Arguments
  - event: The event set for the timeout
  - state: the current state
  - data: the full data of the `:gen_statem` process
  """
  @callback handle_event_timeout(event :: term(), state :: String.t(), data :: t()) ::
              callback_result()

  @optional_callbacks handle_resource: 4,
                      handle_call: 4,
                      handle_cast: 3,
                      handle_info: 3,
                      handle_enter: 3,
                      handle_transition: 3,
                      handle_termination: 3,
                      handle_generic_timeout: 3,
                      handle_state_timeout: 3,
                      handle_event_timeout: 3

  defmodule Edge do
    @moduledoc """
    Represents a transition from one state to another
    """
    defstruct [:source, :target, :event]

    @type t :: %__MODULE__{
            source: String.t(),
            target: String.t(),
            event: Macro.expr()
          }
  end

  defmodule Choice do
    @moduledoc """
    Represents a choice option in a Choice type state
    """
    defstruct [:string_equals, :next]

    @type t :: %__MODULE__{
            string_equals: Macro.expr(),
            next: String.t()
          }
  end

  defmodule Catch do
    @moduledoc """
    Represents a catch error in a Task type state
    """
    defstruct [:error_equals, :next]

    @type t :: %__MODULE__{
            error_equals: [Macro.expr()],
            next: String.t()
          }
  end

  defmodule Node do
    @moduledoc """
    Represents any state in our graph 
    """
    defstruct [
      :type,
      :default,
      :next,
      :iterator,
      :items_path,
      :catch,
      :choices,
      :branches,
      :seconds,
      :timestamp,
      :seconds_path,
      :timestamp_path,
      :resource,
      :parameters,
      :input_path,
      :resource_path,
      :output_path,
      :event,
      :is_end
    ]

    @type t :: %__MODULE__{
            type: String.t(),
            default: String.t() | nil,
            next: String.t() | nil,
            iterator: String.t() | nil,
            items_path: String.t() | nil,
            branches: [String.t()] | nil,
            seconds: float() | integer() | nil,
            timestamp: DateTime.t() | nil,
            seconds_path: String.t() | nil,
            timestamp_path: String.t() | nil,
            catch: [Catch.t()] | [],
            choices: [Choice.t()] | [],
            resource: String.t() | nil,
            parameters: %{},
            input_path: String.t() | nil,
            resource_path: String.t() | nil,
            output_path: String.t() | nil,
            event: [any()] | nil,
            is_end: boolean()
          }
  end

  @derive Jason.Encoder

  defstruct [:_parent, :_parent_data, :data, _tasks: []]

  @typedoc """
  Passed to all processes as the data for the [:gen_statem.data](http://erlang.org/doc/man/gen_statem.html#type-data).

  - `_parent` is used to reference a parent process within a `Map` or `Parallel` state type
  - `_parent_data` is the data from the parent
  - `data` is the data passed to this process on startup
  - `_tasks` is used to keep track of child processes for `Map` and `Parallel` state types
  """
  @type t :: %__MODULE__{_parent: pid(), _parent_data: any(), data: any(), _tasks: []}

  defmacro __using__(data: data) when is_map(data) do
    case validate(data) do
      {:ok, data} -> do_start(data)
      {:error, _} = error -> throw(error)
    end
  end

  defmacro __using__(data: data) when is_binary(data) do
    data
    |> File.read!()
    |> Jason.decode!()
    |> do_start()
  end

  @spec do_start(map()) :: [any()]
  defp do_start(data) when is_map(data) do
    %Graph{} = graph = Graph.serialize(data)
    AST.default(graph) ++ AST.start(graph) ++ AST.graph(graph) ++ AST.catch_all()
  end

  @doc """
  Validates our graph data against the included JSON Schema. This is run automatically at compilation time.
  """
  @spec validate(map()) :: {:ok, map()} | {:error, Validator.result()}
  def validate(data) do
    case JsonXema.validate(@schema, data) do
      :ok ->
        {:ok, data}

      error ->
        {:error, error}
    end
  end
end
