defmodule DummyGraphServer.ServerRateLimiter do
  @moduledoc """
  This is the server-side rate limiter. 
  """
  use GenServer
  require Logger

  @time_interval_milliseconds 5 * 1000
  @tokens_per_time_interval 15

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def get_token() do
    GenServer.call(__MODULE__, :get_token)
  end

  def demo_pull_tokens() do
    1..30
    |> Stream.map(fn _ ->
      Process.sleep(100)
      :ok
    end)
    |> Stream.map(fn _ -> get_token() end)
    |> Enum.to_list()
  end

  # Server API

  @impl GenServer
  def init(_) do
    {time_interval, token_count} = {@time_interval_milliseconds, @tokens_per_time_interval}
    {:ok, timer_ref} = :timer.send_interval(time_interval, self(), {:refresh_tokens, token_count})

    {:ok,
     %{
       count: token_count,
       timer_ref: timer_ref,
       time_interval: time_interval,
       refreshed_at: DateTime.utc_now()
     }}
  end

  @impl GenServer
  def handle_info({:refresh_tokens, new_tokens}, state) do
    state
    |> set_token(new_tokens)
    |> noreply()
  end

  @impl GenServer
  def handle_call(:get_token, _caller, state = %{count: 0}) do
    state
    |> reply({:no_tokens_available, how_long(state)})
  end

  def handle_call(:get_token, _caller, state = %{count: count}) when count > 0 do
    state
    |> decrement_token()
    |> reply({:ok, state.count - 1, how_long(state)})
  end

  def set_token(state, token_count) do
    %{state | count: token_count, refreshed_at: DateTime.utc_now()}
  end

  def decrement_token(state) do
    %{state | count: state.count - 1}
  end

  defp how_long(state) do
    state.time_interval - DateTime.diff(DateTime.utc_now(), state.refreshed_at, :millisecond)
  end

  defp noreply(state), do: {:noreply, state}

  defp reply(state, response), do: {:reply, response, state}
end
