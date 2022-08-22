defmodule KVServer do
  require Logger

  @doc """
  Starts listening connections on the given `port`.
  """
  def listen(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info("Accepting connections on port #{port}")
    accept_connection_loop(socket)
  end

  defp accept_connection_loop(socket) do
    {:ok, connected_socket} = :gen_tcp.accept(socket)
    # aceita a conexão e dispara uma task para executar tal conexão
    {:ok, pid} = Task.Supervisor.start_child(KVServer.TaskSupervisor, fn -> serve(connected_socket) end)

    # This makes the child process the “controlling process” of the client socket.
    #If we didn’t do this, the acceptor would bring down all the clients if it crashed
    # because sockets would be tied to the process that accepted them
    # (which is the default behaviour).
    :ok = :gen_tcp.controlling_process(connected_socket, pid)

    accept_connection_loop(socket)
  end

  defp serve(socket) do
    socket
    |> read_line()
    |> write_line(socket)

    serve(socket)
  end

  defp read_line(socket) do
    {:ok, data} = :gen_tcp.recv(socket, 0)
    data
  end

  defp write_line(data, socket) do
    :gen_tcp.send(socket, data)
  end
end
