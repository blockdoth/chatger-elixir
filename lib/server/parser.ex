defmodule Chatger.Server.Parser do
  import Bitwise
  alias Chatger.Protocol.{Header, Client, Server}

  def parse(data) do
    IO.puts("Balls")

    with {:ok, header, rest} <- Header.parse(data) do
      IO.puts("received packet #{header.packet_id}")
      is_server = (header.packet_id &&& 0x80) != 0
      parser = if is_server, do: Server, else: Client

      parser.parse(header.packet_id, rest)
    end
  end
end
