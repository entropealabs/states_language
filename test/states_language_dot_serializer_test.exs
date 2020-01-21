defmodule StatesLanguageDotSerializerTest do
  require Logger
  use ExUnit.Case, async: true
  alias StatesLanguage.Serializer.Dot
  alias StatesLanguage.Graph

  test "graph structure is maintained when serializing to dot graph format" do
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

        %Graph{} = Graph.serialize(data)

        graph = Dot.serialize(data)

        Logger.info(graph)
      end
    end)
  end
end
