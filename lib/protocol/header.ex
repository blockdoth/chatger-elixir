require Logger

defmodule Chatger.Protocol.Header do
  defstruct [:version, :packet_id, :length]
  # -> CHTG
  @magic_number 0x43485447

  # [magic_number|4][version|1][user/server+packet_id|1][length|4][ packet content ]
  def deserialize(<<@magic_number::32, version::8, packet_id::8, length::32, rest::binary>>) do
    Logger.debug("deserialized header: version:1 #{version}, packet_id: #{packet_id}, length: #{length}")

    {:ok,
     %__MODULE__{
       version: version,
       packet_id: packet_id,
       length: length
     }, rest}
  end

  def serialize(version, packet_id, length) do
    <<@magic_number::32, version::8, packet_id::8, length::32>>
  end
end
