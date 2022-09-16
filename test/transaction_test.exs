defmodule TransactionTest do
  use TestSupport
  use ExUnit.Case
  doctest SupplyChain

  test "calculate correct money value" do
    sellTransaction = %Transaction{from: "player1", to: "player2", amount: 10, price: 5, type: :sell}
    assert Transaction.money_value(sellTransaction) == 50
    buyTransaction = %Transaction{from: "player1", to: "player2", amount: 10, price: 5, type: :buy}
    assert Transaction.money_value(buyTransaction) == -50
  end
end
