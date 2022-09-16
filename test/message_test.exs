defmodule MessageTest do
  use ExUnit.Case
  use TestSupport
  doctest SupplyChain.Core.Message, import: true

  test "create_transactions" do
    messages = [
      Message.new_offer("player1", 15, 15),
      Message.new_buy("player2", "player1", 5),
      Message.new_buy("player3", "player1", 10),
      Message.new_buy("player4", "player1", 15)
    ]

    transactions = Message.create_transactions(messages)
    assert length(transactions) == 2
    [first | [second]] = transactions
    assert first.from == "player1"
    assert first.to == "player3"
    assert first.amount == 10
    assert first.price == 15
    assert second.from == "player1"
    assert second.to == "player2"
    assert second.amount == 5
    assert second.price == 15
  end

end
