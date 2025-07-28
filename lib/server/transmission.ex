defmodule Chatger.Server.Transmission do
  alias Chatger.Protocol.Header
  alias Chatger.Protocol.SerializablePacket

  def send_packet(socket, packet) do
    payload_bin = SerializablePacket.serialize(packet)

    packet_id = SerializablePacket.packet_id(packet)

    header_bin = Header.serialize(1, packet_id, byte_size(payload_bin))

    :gen_tcp.send(socket, header_bin <> payload_bin)
  end

  def recv_packet(socket, _binary) do
  end
end
