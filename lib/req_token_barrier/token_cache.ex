defmodule ReqTokenBarrier.TokenCache do
  use GenServer
  require Logger
  alias ReqTokenBarrier.{QueueUtil, UserQuota}

  defstruct token_count: 1, caller_count: 0, caller_queue: :queue.new(), timer_ref: nil

  @proceed_response :please_proceed

  # Client API

  def start(initial_count) do
    GenServer.start(__MODULE__, initial_count)
  end

  def get_token(pid) do
    GenServer.call(pid, :get_token, :infinity)
  end

  def set_quota(pid, quota) do
    GenServer.cast(pid, {:set_quota, %UserQuota{} = quota})
  end

  # Server API
  @impl GenServer
  def init(initial_count) do
    {:ok, %__MODULE__{token_count: initial_count}}
  end

  @impl GenServer
  def handle_call(:get_token, caller, state = %__MODULE__{token_count: 0}) do
    {:noreply,
     %{
       state
       | caller_count: state.caller_count + 1,
         caller_queue: :queue.in(caller, state.caller_queue)
     }}
  end

  def handle_call(:get_token, _caller, state = %__MODULE__{}) do
    {:reply, @proceed_response, %{state | token_count: state.token_count - 1}}
  end

  @impl GenServer
  def handle_cast({:set_quota, quota = %UserQuota{}}, state = %__MODULE__{caller_count: 0}) do
    state =
      state |> create_new_timer(quota)

    {:noreply, %{state | token_count: quota.remaining}}
  end

  def handle_cast({:set_quota, quota = %UserQuota{remaining: remaining}}, state = %__MODULE__{})
      when is_integer(remaining) and remaining > 0 do
    state =
      state |> create_new_timer(quota)

    {_, %{queue: queue, items: callers, items_count: items_count}} =
      QueueUtil.out_top_items(state.caller_queue, state.caller_count)

    Enum.each(callers, &GenServer.reply(&1, @proceed_response))

    state = %{
      state
      | token_count: remaining - items_count,
        caller_count: state.caller_count - items_count,
        caller_queue: queue
    }

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:new_tokens_should_be_available, new_tokens_per_reset}, state = %__MODULE__{}) do
    state = %__MODULE__{state | token_count: new_tokens_per_reset, timer_ref: nil}

    {_, %{queue: queue, items: callers, items_count: items_count}} =
      QueueUtil.out_top_items(state.caller_queue, state.caller_count)

    Enum.each(callers, &GenServer.reply(&1, @proceed_response))

    state = %__MODULE__{
      state
      | token_count: state.token_count - items_count,
        caller_count: state.caller_count - items_count,
        caller_queue: queue
    }

    {:noreply, state}
  end

  defp create_new_timer(%__MODULE__{} = state, %UserQuota{} = quota) do
    case state.timer_ref do
      nil ->
        :ok

      x ->
        :timer.cancel(x)
    end

    {:ok, timer_ref} =
      :timer.send_after(
        quota.resets_after_ms,
        self(),
        {:new_tokens_should_be_available, quota.new_tokens_per_reset}
      )

    %__MODULE__{state | timer_ref: timer_ref}
  end
end
