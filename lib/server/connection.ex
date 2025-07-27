defmodule Chatger.Server.Connection do
  use GenServer

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def init(socket: socket) do
    case :inet.peername(socket) do
      {:ok, {ip, port}} ->
        IO.puts("Client connected from #{:inet_parse.ntoa(ip) |> to_string()}:#{port}")

      {:error, _} ->
        IO.puts("Client connected (peer info not available)")
    end

    :inet.setopts(socket, active: true, packet: :line)
    {:ok, %{socket: socket}}
  end

  def handle_info({:tcp, socket, data}, state) do
    IO.puts("Received: #{data}")
    :gen_tcp.send(socket, "Echo: #{data}")
    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    IO.puts("Client disconnected")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    IO.puts("TCP error: #{inspect(reason)}")
    {:stop, reason, state}
  end
end
