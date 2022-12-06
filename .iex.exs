alias SupplyChain.Boundary.GameSession
factory_list = [{1,2}, {3,4}, {5,6}]
:observer.start


test_fn = fn ->
  {:ok, name} = GameSession.new_game(factory: factory_list)
  GameSession.join(name, "1")
  GameSession.join(name, "2")
  GameSession.next_round(name)
  GameSession.send_buy_message(name, "2", "factory", 1)
  name
end
