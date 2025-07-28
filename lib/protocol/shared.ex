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
