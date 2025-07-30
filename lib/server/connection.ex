require Logger

defmodule Chatger.Server.Connection do
  use GenServer
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

    :inet.setopts(socket, active: :once)

    Registry.register(Chatger.ConnectionRegistry, :connections, self())
    {:ok, %{socket: socket, buffer: "", user_id: nil}}
  end

  def handle_info({:tcp, socket, data}, %{buffer: buffer, user_id: user_id} = state) do
    new_buffer = buffer <> data

    # Parse 1 or more packets from the current buffer
    {packets, rest} = Transmission.recv_packet(new_buffer)

    {:ok, new_user_id} = Handler.handle_packets(socket, packets, user_id)

    # Mark that we are ready to receive a new packet
    :inet.setopts(state.socket, active: :once)
    {:noreply, %{state | buffer: rest, user_id: new_user_id}}
  end

  def handle_info({:broadcast, packet, origin_id}, state) do
    if origin_id != state.user_id do
      Chatger.Server.Transmission.send_packet(state.socket, packet)
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
