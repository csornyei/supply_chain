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

  @spec money_value(%{
          :amount => number,
          :price => number,
          :type => :buy | :sell,
          optional(any) => any
        }) :: number
  def money_value(%{type: type, amount: amount, price: price}) when type == :buy do
    amount * price * -1
  end
  def money_value(%{type: type, amount: amount, price: price}) when type == :sell do
    amount * price
  end
end
