defmodule DummyGraphServer.Application do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Although we don't use the supervisor name below directly,
    # it can be useful when debugging or introspecting the system.
    DummyGraphServer.Supervisor.start_link(name: DummyGraphServer.Supervisor)
  end
end
