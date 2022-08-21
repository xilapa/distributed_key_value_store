defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  @shopping "shopping"
  @milk "milk"

  setup context do
    nome = context[:test]
    _ = start_supervised!({KV.Registry, name: nome})
    %{registry: nome}
  end

  test "spawn buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, @shopping) == :error

    KV.Registry.create(registry, @shopping)
    assert {:ok, bucket} = KV.Registry.lookup(registry, @shopping)

    KV.Bucket.put(bucket, @milk, 1)
    assert KV.Bucket.get(bucket, @milk) == 1
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, @shopping)
    assert {:ok, bucket} = KV.Registry.lookup(registry, @shopping)

    Agent.stop(bucket)

    # Do a call to ensure the registry processed the DOWN message
    _ = KV.Registry.create(registry, "bogus")

    assert KV.Registry.lookup(registry, @shopping) == :error
  end

  test "removes buckets on crash", %{registry: registry} do
    KV.Registry.create(registry, @shopping)
    assert {:ok, bucket} = KV.Registry.lookup(registry, @shopping)

    Agent.stop(bucket, :shutdown)

    # Do a call to ensure the registry processed the DOWN message
    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, @shopping) == :error
  end
end
