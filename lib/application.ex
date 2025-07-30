defmodule Chatger.Application do
  use Application

  def start(_type, _args) do
    children = [
      Chatger.Database,
      {Chatger.Server.Acceptor, 4348}
    ]

    opts = [strategy: :one_for_one, name: Chatger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
