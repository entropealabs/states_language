defmodule StatesLanguage.SchemaLoader do
  @moduledoc false

  @behaviour Xema.Loader

  @spec fetch(URI.t()) :: {:ok, any} | {:error, any}
  def fetch(uri),
    do:
      :states_language
      |> :code.priv_dir()
      |> Path.join(uri.path)
      |> File.read!()
      |> Jason.decode()
end
