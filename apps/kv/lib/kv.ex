defmodule KV do
  use Application

  @impl Application
  def start(_start_type,_start_args) do
    KV.Supervisor.start_link(name: KV.Supervisor)
  end
end
