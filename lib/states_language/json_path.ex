defmodule StatesLanguage.JSONPath do
  @moduledoc """
  Functions for handling JSONPath support
  """
  def get_parameters(data, input_path, parameters) when is_binary(input_path) do
    get_parameters(data, [input_path], parameters)
  end

  def get_parameters(data, input_path, parameters) when is_list(input_path) do
    input_path
    |> Enum.reduce(data, &run_json_path/2)
    |> generate_parameters(parameters)
  end

  def put_result(data, resource_path, output_path, parameters) do
    result =
      parameters
      |> put_path(resource_path, data)

    run_json_path(output_path, result)
  end

  def run_json_path("$", data), do: data

  def run_json_path(path, %{__struct__: _} = data) do
    run_json_path(path, Map.from_struct(data))
  end

  def run_json_path(<<"$", rest::binary>>, data) when is_map(data) do
    Elixpath.get!(data, rest)
  end

  def run_json_path(_p, data), do: data

  def put_path(_input, "$", result), do: result

  def put_path(%{__struct__: _} = input, path, result) do
    put_path(Map.from_struct(input), path, result)
  end

  def put_path(input, <<"$.", path::binary>>, result) when is_map(input) do
    path =
      path
      |> String.split(".")
      |> Enum.reverse()
      |> Enum.reduce([], fn key, acc ->
        create_path(key, acc)
      end)

    put_in(input, Enum.map(path, &Access.key(&1, %{})), result)
  end

  defp create_path(<<":", key::binary>>, acc) do
    key = String.to_existing_atom(key)
    create_path(key, acc)
  end

  defp create_path(key, acc) do
    [key | acc]
  end

  def generate_parameters(input, params) when map_size(params) == 0, do: input

  def generate_parameters(input, params) do
    Enum.reduce(params, %{}, fn {k, v}, acc -> parse_parameters({k, v}, input, acc) end)
  end

  defp parse_parameters({k, v}, input, acc) when is_map(v) do
    Map.put(acc, k, generate_parameters(input, v))
  end

  defp parse_parameters({k, v}, input, acc) when is_list(v) do
    Map.put(
      acc,
      k,
      Enum.map(v, fn i ->
        generate_parameters(input, i)
      end)
    )
  end

  defp parse_parameters({k, <<"$", _path::binary>> = v}, input, acc) do
    if String.ends_with?(k, ".$") do
      key = String.slice(k, 0..-3)
      val = run_json_path(v, input)
      Map.put(acc, key, val)
    else
      Map.put(acc, k, v)
    end
  end

  defp parse_parameters({k, v}, _input, acc) do
    Map.put(acc, k, v)
  end
end
