defmodule KV.Registry do
  use GenServer

  @type t() :: pid() | {atom(), node()} | atom() | {:global, any()} | {:via, module(), any()}

  # Client API

  @doc """
  Starts the registry server.
  """
  @spec start_link([{atom(), any()}]) :: {:ok, pid()} | {:error, {:already_started, pid()}} | {:error, any()}
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the `bucket` `pid` for `name` in the `registry server`
  """
  @spec lookup(KV.Registry.t(), String.t()) :: {:ok, any()} | :error
  def lookup(registry_server, name) do
    GenServer.call(registry_server, {:lookup, name})
  end

  @doc """
  Ensure the `bucket` with the given `name` is created on `registry_server`
  """
  @spec create(KV.Registry.t(), String.t()) :: :ok
  def create(registry_server, name) do
    GenServer.cast(registry_server, {:create, name})
  end

  # GenServer Callbacks
  @impl GenServer
  def init(:ok) do
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
