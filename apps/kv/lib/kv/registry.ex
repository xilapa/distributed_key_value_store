defmodule KV.Registry do
  use GenServer

  @type t() :: pid() | {atom(), node()} | atom() | {:global, any()} | {:via, module(), any()}

  # Client API

  @doc """
  Starts the registry server.
  """
  @spec start_link([{atom(), any()}]) :: {:ok, pid()} | {:error, {:already_started, pid()}} | {:error, any()}
  def start_link(opts) do
    registry_server_name = Keyword.fetch!(opts, :name)
    GenServer.start_link(__MODULE__, registry_server_name, opts)
  end

  @doc """
  Looks up the `bucket` `pid` for `name` in the `registry server`
  """
  @spec lookup(KV.Registry.t(), String.t()) :: {:ok, any()} | :error
  def lookup(registry_server, name) do
    case :ets.lookup(registry_server, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  @doc """
  Ensure the `bucket` with the given `name` is created on `registry_server`
  """
  @spec create(KV.Registry.t(), String.t()) :: :ok
  def create(registry_server, name) do
    GenServer.call(registry_server, {:create, name})
  end

  # GenServer Callbacks
  @impl GenServer
  def init(registry_server_name) do
    names = :ets.new(registry_server_name,[:named_table, read_concurrency: true]) # correlates bucket names and pids
    refs = %{} # correlates refs and bucket names
    {:ok, {names, refs}}
  end

  @impl GenServer
  def handle_call({:create, name}, _from, {names, refs}) do
    case lookup(names, name) do
      {:ok, bucket} ->
        {:reply, bucket, {names, refs}}
      :error ->
        {:ok, bucket} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        ref = Process.monitor(bucket)
        refs = Map.put(refs, ref, name)
        :ets.insert(names, {name, bucket})
        {:reply, bucket, {names, refs}}
    end
  end

  @impl GenServer
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  @impl GenServer
  def handle_info(msg, state) do
    require Logger
    Logger.debug("Unexpected message on Registry: #{inspect(msg)}")
    {:noreply, state}
  end
end
