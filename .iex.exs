factory_list = [{1,2}, {3,4}, {5,6}]
:observer.start


test_fn = fn ->
  {:ok, name, _} = SupplyChain.start_game(factory: factory_list)
  SupplyChain.join(name, "1")
  SupplyChain.join(name, "2")
  SupplyChain.next_round(name)
  SupplyChain.send_buy_message(name, "2", "factory", 1)
  name
end
