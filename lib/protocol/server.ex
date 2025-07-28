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

    def serialize(%{status: status, error_message: nil}) do
      {:ok, <<status::8>>}
    end

    def serialize(%{status: status, error_message: msg}) do
      {:ok, <<status::8, msg::binary>>}
    end
  end

  defmodule LoginAckPacket do
    defstruct [:status, :error_message]
  end

  defimpl SerializablePacket, for: LoginAckPacket do
    def packet_id(_), do: 0x01

    def serialize(%{status: status, error_message: nil}) do
      {:ok, <<status::8>>}
    end

    def serialize(%{status: status, error_message: msg}) do
      {:ok, <<status::8, msg::binary>>}
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
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
  end

  defmodule ChannelsPacket do
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
  end

  defmodule HistoryPacket do
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
  end

  defmodule UserStatusesPacket do
    defstruct []

    def serialize(_packet), do: {:error, :not_implemented}
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
