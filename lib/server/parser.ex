require Logger

defmodule Chatger.Server.Parser do
  import Bitwise
  alias Chatger.Protocol.{Header, Client, Server}

  def deserialize(data) do
    with {:ok, header, rest} <- Header.deserialize(data) do
      Logger.info("Received packet with ID #{header.packet_id}")
      is_user = (header.packet_id &&& 0x80) != 0
      parser = if is_user, do: Client, else: Server
      parser.deserialize(header.packet_id, rest)
    end
  end
end
