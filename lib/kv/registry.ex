defmodule KV.Registry do
  use GenServer

  # TODO: Client API

  # GenServer Callbacks
  @impl GenServer
  def init(_initial_state) do
    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:lookup, name}, _from, names) do
    {:reply, Map.fetch(names, name), names}
  end

  @impl GenServer
  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link([])
      {:noreply, Map.put(names, name, bucket)}
    end
  end
end
