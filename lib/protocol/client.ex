require Logger

defprotocol Chatger.Protocol.DeserializablePacket do
  def deserialize(binary)
end

defmodule Chatger.Protocol.Client do
  alias Chatger.Protocol.Shared.HealthCheckPacket

  alias __MODULE__.{
    LoginPacket,
    SendMessagePacket,
    SendGetMediaPacket,
    GetChannelsListPacket,
    GetChannelsPacket,
    GetHistoryPacket,
    GetUserStatusesPacket,
    GetUsersPacket,
    GetMediaPacket,
    SendTypingPacket,
    SendStatusPacket
  }

  def deserialize(0x80, binary), do: HealthCheckPacket.deserialize(binary)
  def deserialize(0x81, binary), do: LoginPacket.deserialize(binary)
  def deserialize(0x82, binary), do: SendMessagePacket.deserialize(binary)
  def deserialize(0x83, binary), do: SendGetMediaPacket.deserialize(binary)
  def deserialize(0x84, binary), do: GetChannelsListPacket.deserialize(binary)
  def deserialize(0x85, binary), do: GetChannelsPacket.deserialize(binary)
  def deserialize(0x86, binary), do: GetHistoryPacket.deserialize(binary)
  def deserialize(0x87, binary), do: GetUserStatusesPacket.deserialize(binary)
  def deserialize(0x88, binary), do: GetUsersPacket.deserialize(binary)
  def deserialize(0x89, binary), do: GetMediaPacket.deserialize(binary)
  def deserialize(0x8A, binary), do: SendTypingPacket.deserialize(binary)
  def deserialize(0x8B, binary), do: SendStatusPacket.deserialize(binary)
  def deserialize(_, _), do: {:error, :unknown_packet}

  defmodule LoginPacket do
    defstruct [:username, :password]

    def deserialize(binary) do
      # Find null byte separator
      case :binary.match(binary, <<0>>) do
        {username_len, 1} ->
          <<username::binary-size(username_len), 0, password::binary>> = binary

          cond do
            byte_size(username) < 3 or byte_size(username) > 128 -> {:error, :invalid_username_length}
            byte_size(password) < 1 or byte_size(password) > 1024 -> {:error, :invalid_password_length}
            true -> {:ok, %LoginPacket{username: username, password: password}}
          end

        :nomatch ->
          {:error, :missing_null_separator}
      end
    end
  end

  defmodule SendMessagePacket do
    defstruct [:channel_id, :reply_id, :media_ids, :message_text]

    def deserialize(<<channel_id::64, reply_id::64, num_media::8, rest::binary>>) do
      media_size = num_media * 8

      <<media_bin::binary-size(media_size), message_text::binary>> = rest

      media_ids = for <<media_id::64 <- media_bin>>, do: media_id

      if byte_size(message_text) <= 65535 do
        {:ok,
         %__MODULE__{
           channel_id: channel_id,
           reply_id: reply_id,
           media_ids: media_ids,
           message_text: message_text
         }}
      else
        {:error, :message_too_long}
      end
    end

    def deserialize(_), do: {:error, :invalid_packet}
  end

  defmodule SendGetMediaPacket do
    defstruct []

    def deserialize(_data), do: {:error, :not_implemented}
  end

  defmodule GetChannelsListPacket do
    defstruct []

    def deserialize(_data), do: {:ok, %__MODULE__{}}
  end

  defmodule GetChannelsPacket do
    defstruct []

    def deserialize(_data), do: {:error, :not_implemented}
  end

  defmodule GetHistoryPacket do
    defstruct []

    def deserialize(_data), do: {:error, :not_implemented}
  end

  defmodule GetUserStatusesPacket do
    defstruct []

    def deserialize(_data), do: {:ok, %__MODULE__{}}
  end

  defmodule GetUsersPacket do
    defstruct []

    def deserialize(_data), do: {:error, :not_implemented}
  end

  defmodule GetMediaPacket do
    defstruct []

    def deserialize(_data), do: {:error, :not_implemented}
  end

  defmodule SendTypingPacket do
    defstruct []

    def deserialize(_data), do: {:error, :not_implemented}
  end

  defmodule SendStatusPacket do
    defstruct [:status]

    def deserialize(<<status::8>>) do
      {:ok,
       %__MODULE__{
         status: status
       }}
    end

    def deserialize(_), do: {:error, :invalid_packet}
  end
end
