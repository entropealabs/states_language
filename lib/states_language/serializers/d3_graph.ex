defmodule StatesLanguage.Serializer.D3Graph do
  @moduledoc """
  Serialize a `StatesLanguage.Graph` into a suitable graph structure for D3. 
  """
  alias StatesLanguage.{Edge, Graph, Node}
  require Logger

  def serialize(%{} = data) do
    %Graph{start: start, nodes: nodes, edges: edges} = Graph.serialize(data)
    d3_nodes = parse_nodes(nodes, start)
    d3_edges = parse_edges(edges, d3_nodes)
    %{nodes: d3_nodes, edges: d3_edges}
  end

  defp parse_nodes(nodes, start) do
    nodes
    |> Enum.sort(fn
      {k1, _}, _ -> k1 == start
      _, _ -> false
    end)
    |> Enum.with_index()
    |> Enum.map(fn {{k, %Node{type: type}}, i} ->
      %{
        name: k,
        label: type,
        id: i
      }
    end)
  end

  defp parse_edges(edges, nodes) do
    Enum.map(edges, fn %Edge{} = edge ->
      %{
        source: get_node_id_from_name(edge.source, nodes),
        target: get_node_id_from_name(edge.target, nodes),
        type: Macro.to_string(edge.event)
      }
    end)
  end

  defp get_node_id_from_name(name, nodes) do
    %{id: id} = Enum.find(nodes, fn %{name: n_name} -> n_name == name end)
    id
  end
end
