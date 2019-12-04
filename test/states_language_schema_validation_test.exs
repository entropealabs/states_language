defmodule StatesLanguageSchemaValidationTest do
  use ExUnit.Case, async: true
  require Logger

  test "StatesLanguage schema validation works" do
    "test/support/"
    |> File.ls!()
    |> Enum.each(fn file ->
      if String.ends_with?(file, ".json") do
        assert {:ok, %{} = data} =
                 "test/support/"
                 |> Path.join(file)
                 |> File.read!()
                 |> Jason.decode!()
                 |> StatesLanguage.validate()
      end
    end)
  end
end
