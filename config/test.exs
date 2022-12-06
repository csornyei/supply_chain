import Config

config :supply_chain_server, SupplyChainServer.Repo,
  username: "matecsornyei",
  hostname: "localhost",
  database: "supply_chain_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox
