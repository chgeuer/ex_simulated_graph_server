defmodule ReqTokenBarrier do
  alias __MODULE__.{TokenCache, UserQuota}
  require Logger

  def attach_now_token_barrier(request) do
    {:ok, token_cache} = TokenCache.start(1)

    request
    |> ReqTokenBarrier.attach(
      extract_quota_from_response:
        &UserQuota.extract_user_quota_from_graph_resource_graph_response/1,
      get_token: fn -> TokenCache.get_token(token_cache) end,
      update_quota: fn quota -> TokenCache.set_quota(token_cache, quota) end
    )
  end

  def attach(request, opts \\ []) do
    request
    |> Req.Request.register_options([
      :get_token,
      :extract_quota_from_response,
      :update_quota
    ])
    |> Req.Request.merge_options(opts)
    |> Req.Request.append_request_steps(get_token: &get_token/1)
    |> Req.Request.append_response_steps(update_quota: &update_quota/1)
  end

  def get_token(%{} = request) do
    case request.options[:get_token] do
      get_token_fun when is_function(get_token_fun) -> get_token_fun.()
      _ -> nil
    end

    request
  end

  def update_quota({%Req.Request{options: o} = request, response}) do
    {extract_quota, update_quota} = {o[:extract_quota_from_response], o[:update_quota]}

    response
    |> extract_quota.()
    |> update_quota.()

    {request, response}
  end
end
