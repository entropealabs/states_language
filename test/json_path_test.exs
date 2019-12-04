defmodule JSONPathTest do
  use ExUnit.Case, async: true

  import StatesLanguage.JSONPath,
    only: [
      generate_parameters: 2,
      get_parameters: 3,
      put_result: 4,
      put_path: 3
    ]

  @data %{
    "bal" => "$124.34",
    "acct" => "232asssd2",
    "items" => [
      1,
      "two",
      "three",
      :four,
      5
    ],
    "data" => %{
      details: %{
        more_items: [
          %{
            key: "test",
            value: "yes"
          },
          %{
            key: "another_test",
            value: "no"
          }
        ]
      }
    }
  }

  test "get_parameters" do
    params = %{
      "test.$" => "$.:more_items[0].:key"
    }

    assert get_parameters(@data, "$.data.:details", params) == %{"test" => "test"}
  end

  test "put_result" do
    assert put_result(42, "$.data.:details.more_output", "$.data.:details", @data) ==
             put_in(get_in(@data, ["data", :details]), ["more_output"], 42)
  end

  test "put_path" do
    result = %{
      "test" => "test"
    }

    resource_path = "$.data.:details.output"

    assert put_path(@data, resource_path, result) ==
             put_in(@data, ["data", :details, "output"], result)
  end

  test "generate_parameters" do
    params = %{
      "items" => [
        %{
          "amount.$" => "$.bal",
          "description.$" => "$.items[2]"
        },
        %{
          "amount.$" => "$.data.:details.:more_items[1].:value",
          "description" => "This is a description"
        }
      ],
      "hello" => %{
        "new_key" => %{
          "nested" => %{
            "one_more_level" => %{
              "value.$" => "$.acct"
            }
          }
        }
      }
    }

    assert generate_parameters(@data, params) == %{
             "items" => [
               %{
                 "amount" => "$124.34",
                 "description" => "three"
               },
               %{
                 "amount" => "no",
                 "description" => "This is a description"
               }
             ],
             "hello" => %{
               "new_key" => %{"nested" => %{"one_more_level" => %{"value" => "232asssd2"}}}
             }
           }
  end
end
