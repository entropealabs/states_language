defmodule StatesLanguageD3SerializerTest do
  require Logger
  use ExUnit.Case, async: true
  alias StatesLanguage.Serializer.D3Graph
  alias StatesLanguage.Graph

  test "graph structure is maintained when serializing to d3 graph format" do
    "test/support/"
    |> File.ls!()
    |> Enum.each(fn file ->
      if String.ends_with?(file, ".json") do
        file_name =
          "test/support/"
          |> Path.join(file)

        data =
          file_name
          |> File.read!()
          |> Jason.decode!()

        %Graph{start: start} = Graph.serialize(data)

        graph = D3Graph.serialize(data)

        assert %{name: ^start} = List.first(graph.nodes)

        assert %{nodes: _nodes, edges: _edges} = graph

        graph
        |> Map.get(:nodes)
        |> Enum.each(fn n ->
          assert in_edges?(n.id, graph.edges)
        end)
      end
    end)
  end

  def in_edges?(_id, []), do: true

  def in_edges?(id, edges) do
    Enum.any?(edges, fn
      %{source: ^id} -> true
      %{target: ^id} -> true
      _ -> false
    end)
  end
end
