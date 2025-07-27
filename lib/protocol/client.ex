defmodule Chatger.Protocol.Client do
  alias __MODULE__.{
    HealthCheckPacket,
    LoginPacket,
    SendMessagePacket,
    SendMediaPacket,
    ChannelsListPacket,
    ChannelsPacket,
    HistoryPacket,
    UserStatusesPacket,
    UsersPacket,
    MediaPacket,
    TypingPacket,
    StatusPacket
  }

  def parse(0x80, binary), do: HealthCheckPacket.parse(binary)
  def parse(0x81, binary), do: LoginPacket.parse(binary)
  def parse(0x82, binary), do: SendMessagePacket.parse(binary)
  def parse(0x83, binary), do: SendMediaPacket.parse(binary)
  def parse(0x84, binary), do: ChannelsListPacket.parse(binary)
  def parse(0x85, binary), do: ChannelsPacket.parse(binary)
  def parse(0x86, binary), do: HistoryPacket.parse(binary)
  def parse(0x87, binary), do: UserStatusesPacket.parse(binary)
  def parse(0x88, binary), do: UsersPacket.parse(binary)
  def parse(0x89, binary), do: MediaPacket.parse(binary)
  def parse(0x8A, binary), do: TypingPacket.parse(binary)
  def parse(0x8B, binary), do: StatusPacket.parse(binary)
  def parse(_, _), do: {:error, :unknown_packet}

  defmodule HealthCheckPacket do
    defstruct [:kind]

    def parse(<<0x00>>) do
      {:ok, %__MODULE__{kind: :ping}}
    end

    def parse(<<0x01>>) do
      {:ok, %__MODULE__{kind: :pong}}
    end

    def parse(_), do: {:error, :unknown_health_check_status}
  end

  defmodule LoginPacket do
    defstruct [:username, :password]

    def parse(data) do
      # Find null byte separator
      case :binary.match(data, <<0>>) do
        {username_len, 1} ->
          <<username::binary-size(username_len), 0, password::binary>> = data

          cond do
            byte_size(username) < 3 or byte_size(username) > 128 -> {:error, :invalid_username_length}
            byte_size(password) < 1 or byte_size(password) > 1024 -> {:error, :invalid_password_length}
            true -> {:ok, %__MODULE__{username: username, password: password}}
          end

        :nomatch ->
          {:error, :missing_null_separator}
      end
    end
  end

  defmodule SendMessagePacket do
    defstruct [:channel_id, :reply_id, :media_ids, :message_text]

    def parse(<<channel_id::64, reply_id::64, num_media::8, rest::binary>>) do
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

    def parse(_), do: {:error, :invalid_packet}
  end

  defmodule SendMediaPacket do
    defstruct []

    def parse(_data), do: {:error, :not_implemented}
  end

  defmodule ChannelsListPacket do
    defstruct []

    def parse(_data), do: {:error, :not_implemented}
  end

  defmodule ChannelsPacket do
    defstruct []

    def parse(_data), do: {:error, :not_implemented}
  end

  defmodule HistoryPacket do
    defstruct []

    def parse(_data), do: {:error, :not_implemented}
  end

  defmodule UserStatusesPacket do
    defstruct []

    def parse(_data), do: {:error, :not_implemented}
  end

  defmodule UsersPacket do
    defstruct []

    def parse(_data), do: {:error, :not_implemented}
  end

  defmodule MediaPacket do
    defstruct []

    def parse(_data), do: {:error, :not_implemented}
  end

  defmodule TypingPacket do
    defstruct []

    def parse(_data), do: {:error, :not_implemented}
  end

  defmodule StatusPacket do
    defstruct [:status]

    def parse(<<status::8>>) do
      {:ok,
       %__MODULE__{
         status: status
       }}
    end
  end
end
