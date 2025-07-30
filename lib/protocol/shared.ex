defmodule Chatger.Protocol.Shared.HealthCheckPacket do
  defstruct [:kind]
  def deserialize(<<0x00::8>>), do: {:ok, %__MODULE__{kind: :ping}}
  def deserialize(<<0x01::8>>), do: {:ok, %__MODULE__{kind: :pong}}
  def deserialize(_), do: {:error, :unknown_health_check_status}
end

defimpl Chatger.Protocol.SerializablePacket, for: Chatger.Protocol.Shared.HealthCheckPacket do
  alias Chatger.Protocol.Shared.HealthCheckPacket
  def packet_id(_), do: 0x00

  def serialize(%HealthCheckPacket{kind: :ping}), do: <<0x00>>
  def serialize(%HealthCheckPacket{kind: :pong}), do: <<0x01>>

  def serialize(%HealthCheckPacket{kind: other}) do
    raise ArgumentError, "Unknown kind: #{inspect(other)}"
  end
end

defmodule Chatger.Protocol.Shared.Debug do
  @packet_names %{
    # Client
    0x80 => "HealthCheckPacket",
    0x81 => "LoginPacket",
    0x82 => "SendMessagePacket",
    0x83 => "SendGetMediaPacket",
    0x84 => "GetChannelsListPacket",
    0x85 => "GetChannelsPacket",
    0x86 => "GetHistoryPacket",
    0x87 => "GetUserStatusesPacket",
    0x88 => "GetUsersPacket",
    0x89 => "GetMediaPacket",
    0x8A => "SendTypingPacket",
    0x8B => "SendStatusPacket",
    # Server
    0x00 => "HealthCheckPacket",
    0x01 => "LoginAckPacket",
    0x02 => "SendMessageAckPacket",
    0x03 => "SendMediaAckPacket",
    0x04 => "ChannelsListPacket",
    0x05 => "ChannelsPacket",
    0x06 => "HistoryPacket",
    0x07 => "UserStatusesPacket",
    0x08 => "UsersPacket",
    0x09 => "TypingPacket",
    0x0A => "TypingPacket",
    0x0B => "StatusPacket"
  }

  def get_packet_name(packet_id) do
    Map.get(@packet_names, packet_id)
  end
end
