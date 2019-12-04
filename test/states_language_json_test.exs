defmodule StatesLanguageJSONTest do
  use ExUnit.Case, async: true

  test "StatesLanguage struct is serializable to JSON" do
    assert Jason.encode!(%StatesLanguage{})
  end
end
