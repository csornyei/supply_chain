import Config

config :supply_chain,
  ecto_repos: [SupplyChain.Repo]

config :logger, :console, level: :info

import_config "#{config_env()}.exs"
