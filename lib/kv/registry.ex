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
    names = %{} # correlates bucket names and pids
    refs = %{} # correlates refs and bucket names
    {:ok, {names, refs}}
  end

  @impl GenServer
  def handle_call({:lookup, name}, _from, state) do
    {names, _} = state
    {:reply, Map.fetch(names, name), state}
  end

  @impl GenServer
  def handle_cast({:create, name}, {names, refs}) do
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, bucket} = KV.Bucket.start_link([])
      ref = Process.monitor(bucket)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, bucket)
      {:noreply, {names, refs}}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl GenServer
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message on Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
