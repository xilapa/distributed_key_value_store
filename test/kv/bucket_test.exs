defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  @milk "milk"

  setup do
    bucket = start_supervised!(KV.Bucket)
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, @milk) == nil

    KV.Bucket.put(bucket, @milk, 3)
    assert KV.Bucket.get(bucket, @milk) == 3
  end

  test "remove and return value by key", %{bucket: bucket} do
    # arrange
    assert KV.Bucket.get(bucket, @milk) == nil
    KV.Bucket.put(bucket, @milk, 3)

    # act
    assert KV.Bucket.delete(bucket, @milk) == 3

    # assert
    assert KV.Bucket.get(bucket, @milk) == nil
  end
end
