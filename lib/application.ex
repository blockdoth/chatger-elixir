defmodule Chatger.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Task, fn -> Chatger.Server.start(4348) end}
    ]

    opts = [strategy: :one_for_one, name: Chatger.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
