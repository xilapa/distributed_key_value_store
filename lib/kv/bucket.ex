defmodule KV.Bucket do
  use Agent

  @type t() :: %{}
  @type key() :: String.t()

  @doc """
  Starts a new `bucket`
  """
  @spec start_link(any) :: {:ok, pid} | {:error, {:already_started, pid}} | {:error, any}
  def start_link(_options) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Get a `value` from the `bucket` by `key`
  """
  @spec get(Bucket.t, Bucket.key) :: any
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`
  and return the `bucket`
  """
  @spec put(Bucket.t, Bucket.key, any) :: :ok
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end
end
