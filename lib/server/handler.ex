defmodule Chatger.Server.Handler do
  require Logger
  alias Chatger.Database.Queries

  alias Chatger.Protocol.Client.{
    GetChannelsListPacket,
    GetChannelsPacket,
    GetHistoryPacket,
    GetUsersPacket,
    GetUserStatusesPacket,
    LoginPacket,
    SendMessagePacket,
    SendStatusPacket,
    SendTypingPacket
  }

  alias Chatger.Protocol.Server.{
    ChannelsListPacket,
    ChannelsPacket,
    HistoryPacket,
    LoginAckPacket,
    SendMessageAckPacket,
    TypingPacket,
    UsersPacket,
    UserStatusesPacket
  }

  alias Chatger.Protocol.Shared.HealthCheckPacket
  alias Chatger.Server.Transmission

  @returnSuccess 0x00
  @returnFail 0x01
  @returnBroadcast 0x02
  @authErrorMessage "Auth required"

  def handle_packets(_socket, [], user_id), do: {:ok, user_id}

  def handle_packets(socket, [packet | rest], user_id) do
    case handle_packet(packet, user_id) do
      {:reply, response, new_user_id} ->
        Transmission.send_packet(socket, response)
        handle_packets(socket, rest, new_user_id)

      {:broadcast, :no_reply, broadcast_response, new_user_id} ->
        Transmission.broadcast_packet(broadcast_response, new_user_id)
        handle_packets(socket, rest, new_user_id)

      {:broadcast, response, broadcast_response, new_user_id} ->
        Transmission.send_packet(socket, response)
        Transmission.broadcast_packet(broadcast_response, new_user_id)
        handle_packets(socket, rest, new_user_id)

      {:no_reply, new_user_id} ->
        {:ok, new_user_id}

      {:error, reason} ->
        Logger.error("Error handling packet: #{inspect(reason)}")
        handle_packets(socket, rest, user_id)
    end
  end

  # Allowed unauthenticated

  def handle_packet(%HealthCheckPacket{kind: :ping}, user_id) do
    Logger.info("Received a ping. Responding with pong.")

    {:reply,
     %HealthCheckPacket{
       kind: :pong
     }, user_id}
  end

  def handle_packet(%HealthCheckPacket{kind: :pong}, user_id) do
    Logger.info("Received a pong. Not sure what to do yet")
    {:no_reply, user_id}
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

  # Requires auth

  def handle_packet(%SendStatusPacket{status: status}, user_id) do
    if user_id == nil do
      {:error, :auth_required}
    end

    Queries.update_status(user_id, status)
    {:no_reply, user_id}
  end

  def handle_packet(%GetChannelsListPacket{}, user_id) do
    if user_id == nil do
      {:reply,
       %ChannelsListPacket{
         status: @returnFail,
         channel_ids: [],
         error_message: @authErrorMessage
       }}
    end

    {:ok, channel_ids} = Queries.get_channels_list()

    {:reply,
     %ChannelsListPacket{
       status: @returnSuccess,
       channel_ids: channel_ids
     }, user_id}
  end

  def handle_packet(%GetUserStatusesPacket{}, user_id) do
    if user_id == nil do
      {:reply,
       %UserStatusesPacket{
         status: @returnFail,
         user_statuses: [],
         error_message: @authErrorMessage
       }}
    end

    {:ok, user_statuses} = Queries.get_user_statuses()

    {:reply,
     %UserStatusesPacket{
       status: @returnSuccess,
       user_statuses: user_statuses
     }, user_id}
  end

  def handle_packet(%GetChannelsPacket{channel_ids: channel_ids}, user_id) do
    if user_id == nil do
      {:reply,
       %ChannelsPacket{
         status: @returnFail,
         channels: [],
         error_message: @authErrorMessage
       }}
    end

    {:ok, channels} = Queries.get_channels(channel_ids)

    {:reply,
     %ChannelsPacket{
       status: @returnSuccess,
       channels: channels
     }, user_id}
  end

  def handle_packet(%GetUsersPacket{user_ids: user_ids}, user_id) do
    if user_id == nil do
      {:reply,
       %UsersPacket{
         status: @returnFail,
         users: [],
         error_message: @authErrorMessage
       }}
    end

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
    if user_id == nil do
      {:reply,
       %HistoryPacket{
         status: @returnFail,
         messages: [],
         error_message: @authErrorMessage
       }}
    end

    Logger.info(
      "Received history request for channel id #{channel_id}, is_reply: #{anchor_is_reply}, anchor: #{anchor}, messages back #{num_messages_back}"
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
    if user_id == nil do
      {:error, :auth_required}
    end

    # typing is not saved in the database
    {:broadcast, :no_reply,
     %TypingPacket{
       is_typing: is_typing,
       user_id: user_id,
       channel_id: channel_id
     }, user_id}
  end

  def handle_packet(
        %SendMessagePacket{
          channel_id: channel_id,
          reply_id: reply_id,
          media_ids: media_ids,
          message_text: message_text
        },
        user_id
      ) do
    if user_id == nil do
      {:reply,
       %SendMessageAckPacket{
         status: @returnFail,
         # Not sure if this is a great default
         message_id: 0,
         error_message: @authErrorMessage
       }}
    end

    reply_id = if reply_id == 0, do: nil, else: reply_id
    {:ok, {message_id, sent_timestamp}} = Queries.save_message(user_id, channel_id, reply_id, media_ids, message_text)

    {:broadcast,
     %SendMessageAckPacket{
       status: @returnSuccess,
       message_id: message_id
     },
     %HistoryPacket{
       status: @returnBroadcast,
       messages: [
         {message_id, sent_timestamp, user_id, channel_id, reply_id, message_text, media_ids}
       ]
     }, user_id}
  end

  def handle_packet(other, user_id) do
    Logger.warning("Unhandled packet: #{inspect(other)} for user id #{user_id}")
    {:no_reply, user_id}
  end
end
