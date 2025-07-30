defmodule Chatger.Server.Connection do
  use GenServer
  require Logger
  alias Chatger.Protocol.Shared.HealthCheckPacket
  alias Chatger.Server.Handler
  alias Chatger.Server.Transmission

  @interval 5_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)

  def init(socket: socket) do
    {:ok, {ip, port}} = :inet.peername(socket)
    ip_string = :inet_parse.ntoa(ip)
    Logger.info("Client connected from #{ip_string}:#{port}")

    :inet.setopts(socket, active: :once)

    Registry.register(Chatger.ConnectionRegistry, :connections, self())
    :timer.send_interval(@interval, :send_healthcheck)
    {:ok, %{socket: socket, buffer: "", user_id: nil, ip: ip_string}}
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
    # Dont broadcast messages to our selves
    if origin_id != state.user_id do
      Transmission.send_packet(state.socket, packet)
    end

    {:noreply, state}
  end

  def handle_info(:send_healthcheck, state) do
    Logger.info("Sending healthcheck to #{state.ip}")

    Transmission.send_packet(state.socket, %HealthCheckPacket{
      kind: :ping
    })

    {:noreply, state}
  end

  def handle_info({:tcp_closed, _socket}, state) do
    Logger.info("Client at #{state.ip} disconnected")
    {:stop, :normal, state}
  end

  def handle_info({:tcp_error, _socket, reason}, state) do
    Logger.error("TCP error: #{inspect(reason)}")
    {:stop, reason, state}
  end
end
