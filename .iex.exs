alias SupplyChain.Boundary.GameSession
factory_list = [{1,2}, {3,4}, {5,6}]



test_fn = fn ->
  {:ok, pid} = GenServer.start(GameSession, factory: factory_list)
  GenServer.call(pid, {:join, "1"})
  GenServer.call(pid, {:join, "2"})
  GenServer.cast(pid, :next_round)
  GenServer.cast(pid, {:buy, "2", "factory", 1})
  GenServer.cast(pid, {:offer, "2", 1, 10})
  GenServer.cast(pid, :next_round)
  pid
end
