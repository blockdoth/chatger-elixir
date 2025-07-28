require Logger

defmodule Chatger.Server.Connection do
  use GenServer
  alias Chatger.Server.Parser
  alias Chatger.Server.Handler
  alias Chatger.Server.Transmission

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def init(socket: socket) do
    case :inet.peername(socket) do
      {:ok, {ip, port}} ->
        Logger.info("Client connected from #{:inet_parse.ntoa(ip) |> to_string()}:#{port}")

      {:error, _} ->
        Logger.error("Client connected (peer info not available)")
    end

    :inet.setopts(socket, active: true)
    {:ok, %{socket: socket}}
  end

  def handle_info({:tcp, socket, data}, state) do
    case Parser.deserialize(data) do
      {:ok, deserialized} ->
        Logger.info(deserialized, label: "Deserialized packet")

        case Handler.handle_packet(deserialized) do
          {:ok, response_packet} ->
            Transmission.send_packet(socket, response_packet)

          {:error, reason} ->
            :gen_tcp.send(socket, reason)
        end

      {:error, reason} ->
        Logger.error("Deserialize error: #{inspect(reason)}")
        :gen_tcp.send(socket, "Invalid packet\n")
    end

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("Client disconnected")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.error("TCP error: #{inspect(reason)}")
    {:stop, reason, state}
  end
end
