require Logger

defmodule Chatger.Server.Transmission do
  alias Chatger.Protocol.{Header, Client, Header}
  alias Chatger.Protocol.SerializablePacket
  import Bitwise

  @api_version 1

  def send_packet(socket, packet) do
    payload_bin = SerializablePacket.serialize(packet)

    packet_id = SerializablePacket.packet_id(packet)
    header_bin = Header.serialize(@api_version, packet_id, byte_size(payload_bin))

    :gen_tcp.send(socket, header_bin <> payload_bin)
  end

  def recv_packet(buffer), do: recv_packet(buffer, [])

  def recv_packet(<<header_bin::binary-size(10), rest_bin::binary>> = full_bin, acc) do
    with {:ok, header} = Header.deserialize(header_bin) do
      Logger.info("Received packet with ID #{header.packet_id}")

      body_len = header.packet_length

      # Check if the reaming buffer contains the whole packet body
      if byte_size(rest_bin) >= body_len do
        <<body::binary-size(body_len), remaining_bin::binary>> = rest_bin

        is_user = (header.packet_id &&& 0x80) != 0
        parser = if is_user, do: Client, else: Server

        with {:ok, packet} = parser.deserialize(header.packet_id, body) do
          # Parse additional packets in buffer
          recv_packet(remaining_bin, [packet | acc])
        end
      else
        # Incomplete, wait for more data
        {Enum.reverse(acc), full_bin}
      end
    end
  end

  def recv_packet(buffer, acc), do: {Enum.reverse(acc), buffer}
end
