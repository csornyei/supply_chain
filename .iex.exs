alias SupplyChain.Boundary.GameSession
factory_list = [{1,2}, {3,4}, {5,6}]
:observer.start


test_fn = fn ->
  {:ok, name} = GameSession.new_game(factory: factory_list, settings: [round_length: 5])
  name
end
