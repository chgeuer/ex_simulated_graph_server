defmodule DummyGraphServer.Supervisor do
  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  defp bandit_listener() do
    [
      scheme: :http,
      ip: {0, 0, 0, 0},
      port: 4000
    ]
  end

  @impl true
  def init(:ok) do
    [
      {DummyGraphServer.ServerRateLimiter, name: DummyGraphServer.ServerRateLimiter},
      {Bandit, [plug: DummyGraphServer.BanditTester] |> Keyword.merge(bandit_listener())}
    ]
    |> Supervisor.init(strategy: :rest_for_one)
  end
end
