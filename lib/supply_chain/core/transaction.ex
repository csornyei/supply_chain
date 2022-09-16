defmodule SupplyChain.Core.Transaction do
  @moduledoc """
    Transactions are the core for the supply chain game.
    Transactions used for calculating the current stored items and money of the player.
    They can have 2 types: buy and sell transactions
  """
  defstruct [:from, :to, :amount, :price, :type]

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  @doc """
  Calculate how the transaction changes the user's product amount

  ## Examples
    iex> buyTransaction = %Transaction{from: "player1", to: "player2", amount: 10, price: 5, type: :buy}
    iex> Transaction.product_change(buyTransaction)
    10

    iex> sellTransaction = %Transaction{from: "player1", to: "player2", amount: 10, price: 5, type: :sell}
    iex> Transaction.product_change(sellTransaction)
    -10
  """
  def product_change(%{type: type, amount: amount}) when type == :buy do
    amount
  end
  def product_change(%{type: type, amount: amount}) when type == :sell do
    amount * -1
  end

  @doc """
  Calculate how much will the player's money change after the transaction.

  ## Examples

    iex> buyTransaction = %Transaction{from: "player1", to: "player2", amount: 10, price: 5, type: :buy}
    iex> Transaction.money_change(buyTransaction)
    -50

    iex> sellTransaction = %Transaction{from: "player1", to: "player2", amount: 10, price: 5, type: :sell}
    iex> Transaction.money_change(sellTransaction)
    50
  """
  def money_change(%{type: type, amount: amount, price: price}) when type == :buy do
    amount * price * -1
  end
  def money_change(%{type: type, amount: amount, price: price}) when type == :sell do
    amount * price
  end
end
