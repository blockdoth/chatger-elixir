defmodule Chatger.Server.Connection do
  use GenServer
  alias Chatger.Server.Parser

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
    case Parser.parse(data) do
      {:ok, parsed} ->
        IO.puts(parsed, label: "Parsed command")
        :gen_tcp.send(socket, "Res: #{inspect(parsed)}")

      {:error, reason} ->
        IO.puts("Parse error: #{inspect(reason)}")
        :gen_tcp.send(socket, "Invalid command\n")
    end

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
