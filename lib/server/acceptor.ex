require Logger

defmodule Chatger.Server.Acceptor do
  def start(port \\ 4348) do
    {:ok, socket} =
      :gen_tcp.listen(port, [
        :binary,
        active: false,
        reuseaddr: true
      ])

    Logger.info("Listening on port #{port}")
    accept_loop(socket)
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
