defmodule KV.Router do
  @doc """
  Dispatch the given `mod`, `fun`, `args` request
  to the appropriate node based on the `bucket`.
  """
  def route(bucket, mod, fun, args) do
    # get the first letter of the bucket name
    first_letter = :binary.first(bucket)

    # try to find the entry on routing table
    entry = Enum.find(routing_table(), fn {enum, _node} -> first_letter in enum end) || no_entry_error(bucket)

    # run the function if the node is the current node, otherwise send to destination node
    if elem(entry,1) == node() do
      apply(mod, fun, args)
    else
      {KV.RouterTasks, elem(entry, 1)}
      |> Task.Supervisor.async(KV.Router, :route, [bucket, mod, fun, args])
      |> Task.await()
    end
  end


  defp routing_table do
    # Replace computer-name with your local machine name
    [{?a..?m, :"foo@computer-name"}, {?n..?z, :"bar@computer-name"}]
  end

  defp no_entry_error(bucket) do
    raise "could not find entry for #{inspect bucket} in table #{inspect routing_table()}"
  end
end
