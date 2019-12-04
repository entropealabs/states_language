defmodule StatesLanguage.Graph do
  @moduledoc """
  Functions for creating a Graph structure from deserialized JSON. This is used by Serializers and the core library. See `StatesLanguage.Serializer.D3Graph`.
  """
  alias StatesLanguage.{Catch, Choice, Edge, Node}

  defstruct [:comment, :edges, :nodes, :start]

  @type t :: %__MODULE__{
          comment: String.t(),
          start: String.t(),
          nodes: %{required(String.t()) => Node.t()},
          edges: [Edge.t()]
        }

  @spec serialize(map()) :: t()
  def serialize(data) do
    {comment, start, nodes} = parse_data(data)
    edges = get_edges(nodes)
    %__MODULE__{comment: comment, edges: edges, nodes: nodes, start: start}
  end

  defp parse_data(data) do
    nodes =
      data
      |> Map.get("States")
      |> to_states()

    {
      Map.get(data, "Comment"),
      Map.get(data, "StartAt"),
      nodes
    }
  end

  defp to_states(%{} = states) do
    Enum.reduce(states, %{}, fn {k, v}, acc ->
      Map.put(acc, k, %Node{
        type: Map.get(v, "Type"),
        default: Map.get(v, "Default"),
        next: Map.get(v, "Next"),
        iterator: Map.get(v, "Iterator") |> encode_module_name(),
        items_path: Map.get(v, "ItemsPath"),
        branches: Map.get(v, "Branches", []) |> encode_module_name(),
        seconds: Map.get(v, "Seconds"),
        timestamp: Map.get(v, "Timestamp") |> get_timestamp(),
        seconds_path: Map.get(v, "SecondsPath"),
        timestamp_path: Map.get(v, "TimestampPath"),
        catch: Map.get(v, "Catch", []) |> parse_catches(),
        choices: Map.get(v, "Choices", []) |> parse_choices(),
        resource: Map.get(v, "Resource"),
        parameters: Map.get(v, "Parameters", %{}) |> Macro.escape(),
        input_path: Map.get(v, "InputPath", "$"),
        resource_path: Map.get(v, "ResourcePath", "$"),
        output_path: Map.get(v, "OutputPath", "$"),
        is_end: Map.get(v, "End", false),
        event: Map.get(v, "TransitionEvent", ":transition") |> escape_string()
      })
    end)
  end

  defp encode_module_name(list) when is_list(list) do
    Enum.map(list, &encode_module_name/1)
  end

  defp encode_module_name(mod) do
    Module.safe_concat([mod])
  end

  def get_edges(nodes) do
    nodes
    |> Enum.flat_map(fn {k, %Node{} = v} ->
      get_edges_for_type(k, v)
    end)
  end

  defp get_edges_for_type(
         name,
         %Node{type: "Choice", choices: choices, event: event, default: default}
       ) do
    choices = get_choices(name, choices)

    case default do
      nil -> choices
      default -> [add_edge(name, default, event) | choices]
    end
  end

  defp get_edges_for_type(
         name,
         %Node{next: next, event: event, catch: catches, is_end: false}
       ) do
    catches =
      Enum.flat_map(catches, fn %Catch{next: cat, error_equals: ee} ->
        Enum.map(ee, fn event ->
          add_edge(name, cat, event)
        end)
      end)

    [add_edge(name, next, event) | catches]
  end

  defp get_edges_for_type(_, %Node{is_end: true}), do: []

  defp get_choices(name, choices) do
    Enum.map(choices, fn %Choice{next: choice, string_equals: event} ->
      add_edge(name, choice, event)
    end)
  end

  defp add_edge(name, transition, event) do
    %Edge{source: name, target: transition, event: escape_string(event)}
  end

  defp parse_choices(choices) do
    Enum.map(choices, fn %{"StringEquals" => se, "Next" => next} ->
      %Choice{string_equals: escape_string(se), next: next}
    end)
  end

  defp parse_catches(catches) do
    Enum.map(catches, fn %{"ErrorEquals" => ee, "Next" => next} ->
      %Catch{error_equals: Enum.map(ee, &escape_string/1), next: next}
    end)
  end

  defp get_timestamp(nil), do: nil

  defp get_timestamp(data) do
    {:ok, dt, _off} = DateTime.from_iso8601(data)
    dt
  end

  def escape_string(string) when is_binary(string) do
    string
    |> Code.eval_string()
    |> elem(0)
    |> Macro.escape()
  end

  def escape_string(ast) when not is_binary(ast), do: ast
end
