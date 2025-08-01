defmodule Chatger.Protocol.Header do
  require Logger
  defstruct [:version, :packet_id, :packet_length]

  # -> CHTG
  @magic_number 0x43485447

  def deserialize(<<@magic_number::32, version::8, packet_id::8, packet_length::32>>) do
    Logger.debug("Received header: version: #{version}, packet_id: 0x#{Integer.to_string(packet_id, 16)}, length: #{packet_length}")

    {:ok,
     %__MODULE__{
       version: version,
       packet_id: packet_id,
       packet_length: packet_length
     }}
  end

  def serialize(version, packet_id, packet_length) do
    <<@magic_number::32, version::8, packet_id::8, packet_length::32>>
  end
end
