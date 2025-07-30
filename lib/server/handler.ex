defmodule Chatger.Server.Handler do
  require Logger
  alias Chatger.Database.Queries
  alias Chatger.Protocol.Client.GetChannelsListPacket
  alias Chatger.Protocol.Client.GetChannelsPacket
  alias Chatger.Protocol.Client.GetHistoryPacket
  alias Chatger.Protocol.Client.GetUsersPacket
  alias Chatger.Protocol.Client.GetUserStatusesPacket
  alias Chatger.Protocol.Client.LoginPacket
  alias Chatger.Protocol.Client.SendStatusPacket
  alias Chatger.Protocol.Client.SendTypingPacket
  alias Chatger.Protocol.Server.ChannelsListPacket
  alias Chatger.Protocol.Server.ChannelsPacket
  alias Chatger.Protocol.Server.HistoryPacket
  alias Chatger.Protocol.Server.LoginAckPacket
  alias Chatger.Protocol.Server.TypingPacket
  alias Chatger.Protocol.Server.UsersPacket
  alias Chatger.Protocol.Server.UserStatusesPacket
  alias Chatger.Protocol.Shared.HealthCheckPacket
  alias Chatger.Server.Transmission

  @returnSuccess 0x00
  @returnFail 0x01

  def handle_packets(_socket, [], user_id), do: {:ok, user_id}

  def handle_packets(socket, [packet | rest], user_id) do
    case handle_packet(packet, user_id) do
      {:reply, response, new_user_id} ->
        Transmission.send_packet(socket, response)
        handle_packets(socket, rest, new_user_id)

      {:broadcast, _response, new_user_id} ->
        Logger.info("Broadcast is not implemented yet")
        handle_packets(socket, rest, new_user_id)

      {:no_reply, new_user_id} ->
        {:ok, new_user_id}

      {:error, reason} ->
        Logger.error("Error handling packet: #{inspect(reason)}")
        handle_packets(socket, rest, user_id)
    end
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
           status: @returnSuccess
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
    Queries.update_status(user_id, status)
    {:no_reply, user_id}
  end

  def handle_packet(%GetChannelsListPacket{}, user_id) do
    {:ok, channel_ids} = Queries.get_channels_list()

    {:reply,
     %ChannelsListPacket{
       status: @returnSuccess,
       channel_ids: channel_ids
     }, user_id}
  end

  def handle_packet(%GetUserStatusesPacket{}, user_id) do
    {:ok, user_statuses} = Queries.get_user_statuses()

    {:reply,
     %UserStatusesPacket{
       status: @returnSuccess,
       user_statuses: user_statuses
     }, user_id}
  end

  def handle_packet(%GetChannelsPacket{channel_ids: channel_ids}, user_id) do
    {:ok, channels} = Queries.get_channels(channel_ids)

    {:reply,
     %ChannelsPacket{
       status: @returnSuccess,
       channels: channels
     }, user_id}
  end

  def handle_packet(%GetUsersPacket{user_ids: user_ids}, user_id) do
    {:ok, users} = Queries.get_users(user_ids)

    {:reply,
     %UsersPacket{
       status: @returnSuccess,
       users: users
     }, user_id}
  end

  def handle_packet(
        %GetHistoryPacket{
          channel_id: channel_id,
          anchor_is_reply: anchor_is_reply,
          anchor: anchor,
          num_messages_back: num_messages_back
        },
        user_id
      ) do
    Logger.info(
      "Received history request for channel id #{channel_id}, is reply #{anchor_is_reply}, anchor #{anchor}, messages back #{num_messages_back}"
    )

    {:ok, messages} =
      if anchor_is_reply do
        Queries.get_history_by_message_anchor(channel_id, anchor, num_messages_back)
      else
        Queries.get_history_by_timestamp_anchor(channel_id, anchor, num_messages_back)
      end

    {:reply,
     %HistoryPacket{
       status: @returnSuccess,
       messages: messages
     }, user_id}
  end

  def handle_packet(%SendTypingPacket{is_typing: is_typing, channel_id: channel_id}, user_id) do
    # typing is not saved in the database
    {:broadcast,
     %TypingPacket{
       is_typing: is_typing,
       user_id: user_id,
       channel_id: channel_id
     }, user_id}
  end

  def handle_packet(other, user_id) do
    Logger.warning("Unhandled packet: #{inspect(other)} for user id #{user_id}")
    {:no_reply, user_id}
  end
end
