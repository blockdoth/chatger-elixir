require Logger

defmodule Chatger.Server.Acceptor do
  use Task

  def start_link(port) do
    GenServer.start_link(__MODULE__, port, name: __MODULE__)
  end

  ## GenServer Callbacks

  def init(port) do
    case :gen_tcp.listen(port, [:binary, active: false, reuseaddr: true]) do
      {:ok, listen_socket} ->
        Logger.info("Listening on port #{port}")
        accept_loop(listen_socket)

      {:error, reason} ->
        Logger.error("Failed to bind to port #{port}: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  defp accept_loop(listen_socket) do
    case :gen_tcp.accept(listen_socket) do
      {:ok, client_socket} ->
        {:ok, pid} = GenServer.start_link(Chatger.Server.Connection, socket: client_socket)
        :ok = :gen_tcp.controlling_process(client_socket, pid)

        accept_loop(listen_socket)

      {:error, reason} ->
        Logger.error("Accept failed: #{inspect(reason)}")
        accept_loop(listen_socket)
    end
  end
end
