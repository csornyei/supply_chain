defmodule TransactionTest do
  use ExUnit.Case
  use TestSupport
  doctest SupplyChain.Core.Transaction, import: true

  test "product_change" do
    transaction = Transaction.new(from: "player1", to: "player2", amount: 10, price: 5)
    assert Transaction.product_change("player1", transaction) == -10
    assert Transaction.product_change("player2", transaction) == 10
    assert Transaction.product_change("player3", transaction) == 0
  end

  test "money_change" do
    transaction = Transaction.new(from: "player1", to: "player2", amount: 10, price: 5)
    assert Transaction.money_change("player1", transaction) == 50
    assert Transaction.money_change("player2", transaction) == -50
    assert Transaction.money_change("player3", transaction) == 0
  end

  test "get_player_current_state" do
    transactions =
      [
        [from: "player1", to: "player2", amount: 10, price: 5],
        [from: "player2", to: "player3", amount: 5, price: 10],
        [from: "player1", to: "player2", amount: 15, price: 10],
        [from: "player2", to: "player3", amount: 15, price: 20],
        [from: "player1", to: "player2", amount: 10, price: 10]
      ]
      |> Enum.map(&Transaction.new(&1))

    assert Transaction.get_player_current_state("player1", transactions, {100, 1000}) ==
             {65, 1300}

    assert Transaction.get_player_current_state("player2", transactions, {0, 1000}) == {15, 1050}
    assert Transaction.get_player_current_state("player3", transactions, {0, 1000}) == {20, 650}
    assert Transaction.get_player_current_state("player4", transactions, {0, 1000}) == {0, 1000}
  end
end
