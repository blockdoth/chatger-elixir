defmodule Chatger.Server.Handler do
  require Logger
  alias Chatger.Protocol.Shared.HealthCheckPacket
  alias Chatger.Protocol.Client.{LoginPacket, SendStatusPacket}
  alias Chatger.Protocol.Server.{LoginAckPacket}
  alias Chatger.Server.Transmission

  @returnSuccess 0x00

  def handle_packet(socket, packet) do
    with {:ok, response} = handle_packet(packet) do
      Transmission.send_packet(socket, response)
    end
  end

  def handle_packet(%HealthCheckPacket{kind: :ping}) do
    Logger.info("Received a ping. Responding with pong.")

    {:ok,
     %HealthCheckPacket{
       kind: :pong
     }}
  end

  def handle_packet(%HealthCheckPacket{kind: :pong}) do
    Logger.info("Received a pong. Responding with ping.")

    {:ok,
     %HealthCheckPacket{
       kind: :ping
     }}
  end

  def handle_packet(%LoginPacket{username: username, password: password}) do
    Logger.info("Received loging attempt for user: #{username} with password: #{password}")

    {:ok,
     %LoginAckPacket{
       status: @returnSuccess,
       error_message: nil
     }}
  end

  def handle_packet(%SendStatusPacket{status: status}) do
    Logger.info("Received status #{status}")

    {:ok}
  end

  def handle_packet(other) do
    Logger.warning("Unhandled packet: #{inspect(other)}")
    :ok
  end
end
