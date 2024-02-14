defmodule DummyGraphServer.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    DummyGraphServer.Supervisor.start_link(name: DummyGraphServer.Supervisor)
  end
end
