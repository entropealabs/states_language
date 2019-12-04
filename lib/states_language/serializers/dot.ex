defmodule StatesLanguage.Serializer.Dot do
  @moduledoc """
  Serializer for `StatesLanguage.Graph` to Graphviz compatible .dot file
  """

  alias StatesLanguage.{Edge, Graph, Node}
  require Logger

  def serialize(%{} = data) do
    %Graph{start: start, nodes: nodes, edges: edges} = Graph.serialize(data)
    nodes = sort_nodes(nodes, start)
    output = parse_nodes("", nodes)
    output = parse_edges(output, edges, nodes)
    "digraph my_graph {\n" <> output <> "}\n"
  end

  defp sort_nodes(nodes, start) do
    nodes
    |> Enum.sort(fn
      {^start, _}, _ -> true
      _, _ -> false
    end)
  end

  defp parse_nodes(output, nodes) do
    nodes
    |> Enum.with_index()
    |> Enum.reduce(output, fn {{k, %Node{}}, i}, acc ->
      acc <> "  node#{i} [label=\"#{k}\", shape=box];\n"
    end)
  end

  defp parse_edges(output, edges, nodes) do
    Enum.reduce(edges, output, fn %Edge{} = edge, acc ->
      source = get_node_index_from_name(edge.source, nodes)
      target = get_node_index_from_name(edge.target, nodes)
      acc <> "  node#{source} -> node#{target} [label=\"#{Macro.to_string(edge.event)}\"];\n"
    end)
  end

  defp get_node_index_from_name(name, nodes) do
    Enum.find_index(nodes, fn
      {^name, _} -> true
      _ -> false
    end)
  end
end
