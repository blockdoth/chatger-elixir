defmodule Chatger.Server.Parser do
  def handle_info({:tcp, _socket, <<type::8, _rest::binary>>}, state) do
    IO.puts("Unknown message type: #{type}")
    {:noreply, state}
  end
end
