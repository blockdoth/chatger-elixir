defmodule Chatger.Protocol.Header do
  defstruct [:version, :packet_id, :length]
  # -> CHTG
  @magic_number 0x43485447

  # [magic_number|4][version|1][user/server+packet_id|1][length|4][ packet content ]
  def parse(<<@magic_number::32, version::8, packet_id::8, length::32, rest::binary>>) do
    {:ok,
     %__MODULE__{
       version: version,
       packet_id: packet_id,
       length: length
     }, rest}
  end

  def parse(_), do: {:error, :invalid_header}
end
