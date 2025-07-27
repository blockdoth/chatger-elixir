defmodule Chatger.Protocol.Server do
  def parse(_), do: {:error, :invalid_header}
end
