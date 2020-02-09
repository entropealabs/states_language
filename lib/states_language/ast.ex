defmodule StatesLanguage.AST do
  @moduledoc false
  require Logger
  alias StatesLanguage.{Base, Edge, Graph, Node}
  alias StatesLanguage.AST.{Default, Enter, Map, Parallel, Task, Transition, Wait}

  defmodule Resource do
    @moduledoc false
    defstruct [
      :name,
      :node
    ]

    @type t :: %__MODULE__{
            name: String.t(),
            node: %Node{}
          }
  end

  @callback create(Resource.t() | Edge.t()) :: any()

  @spec graph(Graph.t()) :: [any()]
  def graph(%Graph{nodes: nodes, edges: edges, comment: comment}) do
    warn_duplicate_edges(edges, comment)

    enter =
      Enum.map(edges, fn %Edge{} = edge ->
        Enter.create(edge)
      end)

    transition =
      Enum.map(edges, fn %Edge{} = edge ->
        Transition.create(edge)
      end)

    resource =
      Enum.map(nodes, fn {k, v} ->
        resource(%Resource{name: k, node: v})
      end)

    enter ++ transition ++ resource
  end

  @spec external_resource(binary() | nil) :: [any()] | []
  def external_resource(nil), do: []

  def external_resource(path) when is_binary(path) do
    [
      quote location: :keep do
        @external_resource unquote(path)
      end
    ]
  end

  @spec start(Graph.t()) :: [any()]
  def start(%Graph{start: start}) do
    [
      Enter.create(%Edge{target: start, source: start})
    ]
  end

  @spec default(Graph.t()) :: [any()]
  def default(%Graph{start: start}) do
    [
      quote location: :keep do
        use Base, start: unquote(start)
        alias StatesLanguage.AST
      end
    ]
  end

  @spec catch_all :: [any()]
  def catch_all do
    [
      Default.create(%Resource{})
    ]
  end

  @spec resource(Resource.t()) :: Macro.expr()
  def resource(%Resource{node: %Node{type: "Wait"}} = state_data) do
    Wait.create(state_data)
  end

  def resource(%Resource{node: %Node{type: "Map"}} = state_data) do
    Map.create(state_data)
  end

  def resource(%Resource{node: %Node{type: "Parallel"}} = state_data) do
    Parallel.create(state_data)
  end

  def resource(%Resource{} = state_data) do
    Task.create(state_data)
  end

  @spec do_stop?(boolean()) :: boolean()
  def do_stop?(true), do: true

  def do_stop?(false), do: false

  @spec wait_duration({atom(), integer() | String.t()}) :: {atom(), integer() | String.t()}
  def wait_duration({:milli, millis}), do: {:milli, millis}
  def wait_duration({:path, path}), do: {:path, path}

  defp warn_duplicate_edges(edges, comment) do
    edges = Enum.with_index(edges)

    Enum.any?(edges, fn {%Edge{source: s, target: t} = e1, i} ->
      Enum.find(edges, fn
        {%Edge{source: ^s, target: ^t}, ^i} ->
          false

        {%Edge{source: ^s, target: ^t} = e2, _ti} ->
          Logger.warn(
            "Duplicate Edge found in graph \"#{comment}\" #{inspect(e1, pretty: true)} and #{
              inspect(e2, pretty: true)
            }"
          )

          true

        _ ->
          false
      end)
    end)
  end
end
