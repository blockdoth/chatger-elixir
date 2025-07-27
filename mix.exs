defmodule ChatgerServer.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatger_server,
      version: "0.1.0",
      elixir: "~> 1.17.3",
      start_permanent: Mix.env() == :prod,
      deps: [],
      escript: [main_module: ChatgerServer],
    ]
  end
end
