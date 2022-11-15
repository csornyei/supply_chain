defmodule SupplyChain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: SupplyChain.Registry.GameSession},
      {DynamicSupervisor, name: SupplyChain.Supervisor.GameSession, strategy: :one_for_one}
    ]

    opts = [strategy: :one_for_one, name: SupplyChain.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
