defmodule Mix.Tasks.StatesLanguage.D3 do
  @moduledoc """
  Outputs a binary version of the D3 serialization suitable for writing to a file
  """
  use Mix.Task

  alias StatesLanguage.Serializer.D3Graph

  @shortdoc "Output D3 graph format"
  def run(file) do
    file
    |> File.read!()
    |> Jason.decode!()
    |> D3Graph.serialize()
    |> Jason.encode!()
    |> Mix.Shell.IO.info()
  end
end
