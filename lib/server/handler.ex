defmodule Chatger.Server.Handler do
  require Logger
  alias Chatger.Protocol.Shared.HealthCheckPacket
  alias Chatger.Protocol.Client.{LoginPacket, SendStatusPacket}
  alias Chatger.Protocol.Server.{LoginAckPacket}
  alias Chatger.Server.Transmission
  alias Chatger.Database.Queries

  @returnSuccess 0x00
  @returnFail 0x01

  def handle_packets(socket, packets) do
    # with {:reply, response, new_user_id} <- handle_packet(packet, user_id) do
    #   Transmission.send_packet(socket, response)
    # else
    #   {:no_reply, new_user_id} -> {:ok, new_user_id}
    #   err -> err
    # end
  end


  def handle_packet(socket, packet, user_id) do
    case handle_packet(packet, user_id) do
      {:reply, response} -> Transmission.send_packet(socket, response)
      {:no_reply} -> {}
      err -> err
    end
  end

  def handle_packet(%HealthCheckPacket{kind: :ping}, user_id) do
    Logger.info("Received a ping. Responding with pong.")

    {:reply,
     %HealthCheckPacket{
       kind: :pong
     }, user_id}
  end

  def handle_packet(%HealthCheckPacket{kind: :pong}, user_id) do
    Logger.info("Received a pong. Responding with ping.")

    {:reply,
     %HealthCheckPacket{
       kind: :ping
     }, user_id}
  end

  def handle_packet(%LoginPacket{username: username, password: password}, user_id) do
    Logger.info("Received loging attempt for user: \"#{username}\" with password: \"#{password}\"")

    case Queries.check_credentials(username, password) do
      {:ok, new_user_id} ->
        {:reply,
         %LoginAckPacket{
           status: @returnSuccess,
           error_message: nil
         }, new_user_id}

      {:error, :not_found} ->
        {:reply,
         %LoginAckPacket{
           status: @returnFail,
           error_message: "User not found"
         }, user_id}
    end
  end

  def handle_packet(%SendStatusPacket{status: status}, user_id) do
    Logger.info("Received status #{status}")
    Queries.update_status(user_id, status)
    {:no_reply, user_id}
  end

  def handle_packet(other, user_id) do
    Logger.warning("Unhandled packet: #{inspect(other)}")
    {:no_reply, user_id}
  end
end
