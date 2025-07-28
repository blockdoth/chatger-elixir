defmodule Chatger.Server.Handler do
  require Logger
  alias Chatger.Protocol.Shared.HealthCheckPacket

  def handle_packet(%HealthCheckPacket{kind: :ping}) do
    Logger.info("Received a ping. Responding with pong.")

    response = %HealthCheckPacket{
      kind: :pong
    }

    {:ok, response}
  end

  def handle_packet(%HealthCheckPacket{kind: :pong}) do
    Logger.info("Received a pong.")

    {:ok}
  end

  def handle_packet(other) do
    Logger.warning("Unhandled packet: #{inspect(other)}")
    :ok
  end
end
