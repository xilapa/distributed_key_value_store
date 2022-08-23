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
    msg =
      with {:ok, data} <- read_line(socket),
      {:ok, command} <- KVServer.Command.parse(data),
      do: KVServer.Command.run(command)

    write_line(socket, msg)

    serve(socket)
  end

  defp read_line(socket) do
    :gen_tcp.recv(socket, 0)
  end

  defp write_line(socket, {:ok, text}) do
    :gen_tcp.send(socket, text)
  end

  defp write_line(socket, {:error, :unknown_command}) do
    # Known error; write to the client
    :gen_tcp.send(socket, "UNKNOWN COMMAND\r\n")
  end

  defp write_line(_socket, {:error, :closed}) do
    # The connection was closed, exit politely
    exit(:shutdown)
  end

  defp write_line(socket, {:error, :not_found}) do
    :gen_tcp.send(socket, "NOT FOUND\r\n")
  end

  defp write_line(socket, {:error, error}) do
    # Unknown error; write to the client and exit
    :gen_tcp.send(socket, "ERROR\r\n")
    exit(error)
  end
end
