require Logger

defprotocol Chatger.Protocol.SerializablePacket do
  def packet_id(packet)
  def serialize(packet)
end

defmodule Chatger.Protocol.Server do
  alias Chatger.Protocol.SerializablePacket

  alias __MODULE__.{
    LoginAckPacket,
    SendMessageAckPacket,
    SendMediaAckPacket,
    ChannelsListPacket,
    ChannelsPacket,
    HistoryPacket,
    UserStatusesPacket,
    UsersPacket,
    MediaPacket,
    TypingPacket,
    StatusPacket
  }

  defmodule LoginAckPacket do
    defstruct [:status, :error_message]
  end

  defimpl SerializablePacket, for: LoginAckPacket do
    def packet_id(_), do: 0x01

    def serialize(%{status: status}) do
      <<status::8>>
    end

    def serialize(%{status: status, error_message: msg}) do
      <<serialize(%{status: status}), msg::binary>>
    end
  end

  defmodule SendMessageAckPacket do
    defstruct [:status, :message_id, :error_message]

    def serialize(_packet) do
    end
  end

  defmodule SendMediaAckPacket do
    defstruct [:status, :media_id, :error_message]

    def serialize(_packet), do: {:error, :not_implemented}
  end

  defmodule ChannelsListPacket do
    defstruct [:status, :channel_ids, :error_message]
  end

  defimpl SerializablePacket, for: ChannelsListPacket do
    def packet_id(_), do: 0x04

    def serialize(%{status: status, channel_ids: channel_ids}) do
      channel_ids_count = length(channel_ids)
      channels_bin = Enum.reduce(channel_ids, <<>>, fn id, acc -> acc <> <<id::64>> end)
      <<status::8, channel_ids_count::16, channels_bin::binary>>
    end

    def serialize(%{status: status, channel_ids: channel_ids, error_message: msg}) do
      <<serialize(%{status: status, channel_ids: channel_ids}), msg::binary>>
    end
  end

  defmodule ChannelsPacket do
    defstruct [:status, :channels, :error_message]
  end

  defimpl SerializablePacket, for: ChannelsPacket do
    def packet_id(_), do: 0x05

    def serialize(%{status: status, channels: channels}) do
      channels_count = length(channels)

      channels_bin =
        Enum.reduce(channels, <<>>, fn {channel_id, name, icon_id}, acc ->
          acc <> <<channel_id::64, byte_size(name)::8, name::binary, icon_id::64>>
        end)

      <<status::8, channels_count::16, channels_bin::binary>>
    end

    def serialize(%{status: status, channels: channels, error_message: msg}) do
      <<serialize(%{status: status, channels: channels}), msg::binary>>
    end
  end

  defmodule HistoryPacket do
    defstruct [:status, :messages, :error_message]
  end

  defimpl SerializablePacket, for: HistoryPacket do
    def packet_id(_), do: 0x06

    def serialize(%{status: status, messages: messages}) do
      message_count = length(messages)

      messages_bin =
        Enum.reduce(messages, <<>>, fn {message_id, sent_timestamp, user_id, channel_id, reply_id, message, media_ids},
                                       acc ->
          acc <>
            <<message_id::64, sent_timestamp::64, user_id::64, channel_id::64, reply_id::64, byte_size(message)::16,
              message::binary, length(media_ids)::16,
              Enum.reduce(media_ids, <<>>, fn media_id, acc -> acc <> <<media_id::64>> end)::binary>>
        end)

      <<status::8, message_count::8, messages_bin::binary>>
    end

    def serialize(%{status: status, messages: messages, error_message: msg}) do
      <<serialize(%{status: status, messages: messages}), msg::binary>>
    end
  end

  # pub status: ReturnStatus,
  # pub users: Vec<(UserId, UserStatus)>,
  # pub error_message: Option<String>,
  defmodule UserStatusesPacket do
    defstruct [:status, :user_statuses, :error_message]
  end

  defimpl SerializablePacket, for: UserStatusesPacket do
    def packet_id(_), do: 0x07

    def serialize(%{status: status, user_statuses: user_statuses}) do
      user_statuses_count = length(user_statuses)
      user_statuses_bin = Enum.reduce(user_statuses, <<>>, fn {id, status}, acc -> acc <> <<id::64, status::8>> end)
      <<status::8, user_statuses_count::16, user_statuses_bin::binary>>
    end

    def serialize(%{status: status, channels_ids: channels_ids, error_message: msg}) do
      <<serialize(%{status: status, channels_ids: channels_ids}), msg::binary>>
    end
  end

  defmodule UsersPacket do
    defstruct [:status, :users, :error_message]
  end

  defimpl SerializablePacket, for: UsersPacket do
    def packet_id(_), do: 0x08

    def serialize(%{status: status, users: users}) do
      user_count = length(users)

      users_bin =
        Enum.reduce(users, <<>>, fn {user_id, status, username, pfp_id, bio}, acc ->
          acc <>
            <<user_id::64, status::8, byte_size(username)::8, username::binary, pfp_id::64, byte_size(bio)::16,
              bio::binary>>
        end)

      <<status::8, user_count::8, users_bin::binary>>
    end

    def serialize(%{status: status, users: users, error_message: msg}) do
      <<serialize(%{status: status, users: users}), msg::binary>>
    end
  end

  defmodule MediaPacket do
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
  end

  defmodule TypingPacket do
    defstruct [:is_typing, :user_id, :channel_id]

    def serialize(%{is_typing: is_typing, user_id: user_id, channel_id: channel_id}) do
      <<is_typing::8, user_id::64, channel_id::64>>
    end
  end

  defmodule StatusPacket do
    defstruct [:status]

    def serialize(<<status::8>>) do
      {:ok,
       %__MODULE__{
         status: status
       }}
    end
  end
end
