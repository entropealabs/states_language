defmodule Mix.Tasks.StatesLanguage.Dot do
  @moduledoc """
  Outputs a binary version of the Dot format suitable for writing to a file
  """
  use Mix.Task

  alias StatesLanguage.Serializer.Dot

  @shortdoc "Output .dot format"
  def run(file) do
    file
    |> File.read!()
    |> Jason.decode!()
    |> Dot.serialize()
    |> Mix.Shell.IO.info()
  end
end
