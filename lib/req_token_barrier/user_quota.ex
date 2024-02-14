defmodule ReqTokenBarrier.UserQuota do
  defstruct remaining: nil, resets_after_ms: nil, new_tokens_per_reset: nil

  alias __MODULE__.DurationParser

  # Azure Resource Graph allocates a quota number for each user based on a time window. 
  # For example, a user can send at most 15 queries within every 5-second window without being throttled. 
  @token_count_on_reset 15

  def extract_user_quota_from_graph_resource_graph_response(%Req.Response{} = response) do
    user_quota_remaining =
      case response
           |> get_in([Access.key(:headers), "x-ms-user-quota-remaining", Access.at(0)]) do
        nil ->
          nil

        val when is_binary(val) ->
          {val, ""} = Integer.parse(val)
          val
      end

    user_quota_resets_after_millis =
      response
      |> get_in([Access.key(:headers), "x-ms-user-quota-resets-after", Access.at(0)])
      |> DurationParser.duration_string_to_millisecond()

    %__MODULE__{
      remaining: user_quota_remaining,
      resets_after_ms: user_quota_resets_after_millis,
      new_tokens_per_reset: @token_count_on_reset
    }
  end
end
