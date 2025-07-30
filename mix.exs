defmodule Chatger.MixProject do
  use Mix.Project

  def project do
    [
      app: :chatger,
      version: "0.1.0",
      elixir: "~> 1.17.3",
      start_permanent: Mix.env() == :prod,
      deps: [
        {:exqlite, "~> 0.27"}
      ],
      escript: [main_module: Chatger]
    ]
  end

  def application do
    [
      mod: {Chatger.Application, []},
      extra_applications: [:logger]
    ]
  end
end
