defmodule ASTTest do
  use ExUnit.Case, async: true
  require Logger
  alias StatesLanguage.{Edge, Graph, Node}
  alias StatesLanguage.AST.{Enter, Map, Parallel, Resource, Task, Transition}

  defp format_ast(ast) do
    ast
    |> Macro.to_string()
  end

  test "Task" do
    f =
      Task.create(%Resource{
        name: "TestState",
        node: %Node{
          type: "Task",
          resource: "TestResource",
          next: "AnotherTestResource",
          event: Graph.escape_string(":success"),
          is_end: false
        }
      })
      |> format_ast()

    assert String.contains?(f, [
             "handle_event(:internal, :handle_resource, \"TestState\" = state, %StatesLanguage{data: data} = sl)",
             "{:keep_state, %StatesLanguage{sl | data: data}, actions}",
             "AST.do_stop?(false)"
           ])
  end

  test "Task with is_end" do
    f =
      Task.create(%Resource{
        name: "TestState",
        node: %Node{
          type: "Task",
          resource: "TestResource",
          next: "AnotherTestResource",
          event: Graph.escape_string(":success"),
          is_end: true
        }
      })
      |> format_ast()

    assert String.contains?(f, [
             "handle_event(:internal, :handle_resource, \"TestState\" = state, %StatesLanguage{data: data} = sl)",
             "{:keep_state, %StatesLanguage{sl | data: data}, actions}",
             "AST.do_stop?(true)"
           ])
  end

  test "Map" do
    f =
      Map.create(%Resource{
        name: "TestState",
        node: %Node{
          type: "Map",
          iterator: TestIterator,
          items_path: "$",
          parameters: %{},
          input_path: "$",
          resource_path: "$",
          output_path: "$",
          event: :transition,
          is_end: false
        }
      })
      |> format_ast()

    assert String.contains?(f, [
             "handle_event(:internal, :handle_resource, \"TestState\" = state, %StatesLanguage{data: data} = sl)",
             "(handle_event(:info, {:task_processed, result, pid}, \"TestState\", %StatesLanguage{_tasks: tasks} = sl)",
             "handle_event(:internal, :await_parallel_tasks, \"TestState\" = state, %StatesLanguage{_tasks: tasks, data: data} = sl)",
             "{:keep_state, %StatesLanguage{sl | data: data, _tasks: []}, [{:next_event, :internal, :transition}]}"
           ])
  end

  test "Parallel" do
    f =
      Parallel.create(%Resource{
        name: "TestState",
        node: %Node{
          type: "Parallel",
          branches: [TestIterator],
          parameters: %{},
          input_path: "$",
          resource_path: "$",
          output_path: "$",
          event: :transition,
          is_end: false
        }
      })
      |> format_ast()

    assert String.contains?(f, [
             "handle_event(:internal, :handle_resource, \"TestState\" = state, %StatesLanguage{data: data} = sl)",
             "handle_event(:info, {:task_processed, result, pid}, \"TestState\", %StatesLanguage{_tasks: tasks} = sl)",
             "handle_event(:internal, :await_parallel_tasks, \"TestState\" = state, %StatesLanguage{_tasks: tasks, data: data} = sl)",
             "{:keep_state, %StatesLanguage{sl | data: data, _tasks: []}, [{:next_event, :internal, :transition}]}"
           ])
  end

  test "Enter" do
    f =
      Enter.create(%Edge{source: "Previous", target: "Current"})
      |> format_ast()

    assert String.contains?(f, [
             "handle_event(:enter, \"Previous\" = source, \"Current\" = target, data)",
             "{:keep_state, data, actions}"
           ])
  end

  test "Transition" do
    f =
      Transition.create(%Edge{
        source: "CurrentState",
        target: "NextState",
        event: Graph.escape_string(":success")
      })
      |> format_ast()

    assert String.contains?(f, [
             "handle_event(:info, :success = event, \"CurrentState\" = state, data)",
             "handle_event(:internal, :success = event, \"CurrentState\" = state, data)",
             "{:next_state, \"NextState\", data, [{:next_event, :internal, :handle_resource} | actions]}"
           ])
  end
end
