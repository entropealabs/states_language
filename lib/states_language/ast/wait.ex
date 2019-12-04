defmodule StatesLanguage.AST.Wait do
  @moduledoc false
  @behaviour StatesLanguage.AST
  alias StatesLanguage.AST.Resource
  alias StatesLanguage.Node

  @impl true
  # credo:disable-for-lines:7
  def create(%Resource{
        name: state_name,
        node:
          %Node{
            next: next_state,
            is_end: is_end
          } = node
      }) do
    duration = get_wait_duration_milliseconds(node)

    quote location: :keep do
      import StatesLanguage.AST.Wait,
        only: [get_timestamp_diff: 1]

      @impl true
      def handle_event(
            :internal,
            :handle_resource,
            unquote(state_name) = state,
            %StatesLanguage{data: data} = sl
          ) do
        debug("Handling Wait resource for #{state}")
        # credo:disable-for-lines:22
        dur =
          case AST.wait_duration(unquote(duration)) do
            {:path, path} ->
              debug("getting wait time from path #{path}")
              val = run_json_path(path, data)

              case val do
                %DateTime{} = future ->
                  get_timestamp_diff(future)

                seconds when is_number(seconds) ->
                  debug("Path value was seconds")
                  trunc(seconds * 1000)

                datetime when is_binary(datetime) ->
                  debug("path value was timestamp")
                  {:ok, future, _off} = DateTime.from_iso8601(datetime)
                  get_timestamp_diff(future)
              end

            {:milli, milliseconds} ->
              milliseconds
          end

        debug("Waiting #{dur}ms in state #{state}")
        {:keep_state_and_data, [{:state_timeout, dur, dur}]}
      end

      @impl true
      def handle_event(
            :state_timeout,
            duration,
            unquote(state_name) = state,
            %StatesLanguage{} = sl
          ) do
        case AST.do_stop?(unquote(is_end)) do
          true ->
            :stop

          false ->
            actions = [{:next_event, :internal, :transition}]

            debug("Moving from #{state} to #{unquote(next_state)} after waiting #{duration}ms")
            {:keep_state_and_data, actions}
        end
      end
    end
  end

  @spec get_timestamp_diff(DateTime.t()) :: integer()
  def get_timestamp_diff(future) do
    DateTime.diff(future, DateTime.utc_now(), :millisecond)
  end

  @spec get_wait_duration_milliseconds(Node.t()) ::
          {:milli, integer()} | {:path, String.t()}
  defp get_wait_duration_milliseconds(%Node{seconds: seconds}) when not is_nil(seconds),
    do: {:milli, trunc(seconds * 1000)}

  defp get_wait_duration_milliseconds(%Node{timestamp: future}) when not is_nil(future) do
    {:milli, get_timestamp_diff(future)}
  end

  defp get_wait_duration_milliseconds(%Node{seconds_path: path}) when not is_nil(path),
    do: {:path, path}

  defp get_wait_duration_milliseconds(%Node{timestamp_path: path}) when not is_nil(path),
    do: {:path, path}
end
