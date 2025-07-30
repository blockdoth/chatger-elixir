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
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
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
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
  end

  defmodule MediaPacket do
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
  end

  defmodule TypingPacket do
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
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
