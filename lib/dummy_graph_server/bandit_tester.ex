defmodule DummyGraphServer.BanditTester do
  require Logger
  alias DummyGraphServer.ServerRateLimiter
  alias ReqTokenBarrier.UserQuota.DurationParser
  import Plug.Conn

  def init(options) do
    options
  end

  defp add_headers(conn, count, diff) do
    diff = DurationParser.millisecond_to_duration_string(diff)

    conn
    |> put_resp_header("x-ms-user-quota-remaining", "#{count}")
    |> put_resp_header("x-ms-user-quota-resets-after", "#{diff}")
  end

  def call(conn, _opts) do
    case ServerRateLimiter.get_token() do
      {:ok, count, diff} ->
        conn
        |> add_headers(count, diff)
        |> send_resp(200, "OK #{count} #{inspect(diff)}")

      {:no_tokens_available, diff} ->
        conn
        |> add_headers(0, diff)
        |> send_resp(421, "Throttling #{diff}")

      error ->
        conn
        |> send_resp(500, "Fuck #{inspect(error)}")
    end
  end
end
