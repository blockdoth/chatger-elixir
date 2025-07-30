require Logger

defmodule Chatger.Server.Transmission do
  alias Chatger.Protocol.Client
  alias Chatger.Protocol.Header
  alias Chatger.Protocol.SerializablePacket
  alias Chatger.Protocol.Shared.Debug
  import Bitwise

  @api_version 1

  def send_packet(socket, packet) do
    body_bin = SerializablePacket.serialize(packet)

    packet_id = SerializablePacket.packet_id(packet)
    header_bin = Header.serialize(@api_version, packet_id, byte_size(body_bin))
    payload_bin = header_bin <> body_bin
    Logger.info("Sending packet #{Debug.get_packet_name(packet_id)} of size #{byte_size(payload_bin)} bytes")
    Logger.debug("Body #{inspect(body_bin)}")
    :gen_tcp.send(socket, payload_bin)
  end

  def recv_packet(buffer), do: recv_packet(buffer, [])

  def recv_packet(<<header_bin::binary-size(10), rest_bin::binary>> = full_bin, acc) do
    case Header.deserialize(header_bin) do
      {:ok, header} ->
        Logger.info(
          "Received packet #{Debug.get_packet_name(header.packet_id)} of length #{header.packet_length} bytes"
        )

        body_len = header.packet_length

        # Check if the reaming buffer contains the whole packet body
        if byte_size(rest_bin) >= body_len do
          <<body::binary-size(body_len), remaining_bin::binary>> = rest_bin

          is_user = (header.packet_id &&& 0x80) != 0
          parser = if is_user, do: Client, else: Server

          case parser.deserialize(header.packet_id, body) do
            {:ok, packet} ->
              # Parse additional packets in buffer
              recv_packet(remaining_bin, [packet | acc])

            {:error, :not_implemented} ->
              Logger.warning("Deserialization not implemented for #{Debug.get_packet_name(header.packet_id)}")
              recv_packet(remaining_bin, acc)

            {:error, reason} ->
              Logger.error("Error while deserializing: #{reason}")
              recv_packet(remaining_bin, acc)
          end
        else
          # Incomplete, wait for more data
          {Enum.reverse(acc), full_bin}
        end

      {:error, reason} ->
        Logger.error("Not sure what do from here #{reason}")
        {:error, :header_deserialization_failed}
    end
  end

  def recv_packet(buffer, acc), do: {Enum.reverse(acc), buffer}

  def broadcast_packet(packet, origin_id) do
    Registry.dispatch(Chatger.ConnectionRegistry, :connections, fn entries ->
      for {pid, _} <- entries do
        send(pid, {:broadcast, packet, origin_id})
      end
    end)
  end
end
