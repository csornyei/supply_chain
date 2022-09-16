defmodule SupplyChain.Core.Transaction do
  @moduledoc """
    Transactions are the core for the supply chain game.
    Transactions used for calculating the current stored products and money of the player.
  """
  defstruct [:from, :to, :amount, :price]

  def new(fields) do
    struct!(__MODULE__, fields)
  end

  @doc """
  Calculate how the transaction changes the user's product amount

  ## Examples
    iex> transaction = new [from: "player1", to: "player2", amount: 10, price: 5]
    iex> product_change("player1", transaction)
    -10
  """
  def product_change(player, %{from: fromPlayer, amount: amount}) when player == fromPlayer do
    -1 * amount
  end

  def product_change(player, %{to: toPlayer, amount: amount}) when player == toPlayer do
    amount
  end

  def product_change(_player, _transaction) do
    0
  end

  @doc """
  Calculate how much will the player's money change after the transaction.

  ## Examples

    iex> transaction = new [from: "player1", to: "player2", amount: 10, price: 5]
    iex> money_change("player1", transaction)
    50
  """
  def money_change(player, %{from: fromPlayer, amount: amount, price: price})
      when player == fromPlayer do
    amount * price
  end

  def money_change(player, %{to: toPlayer, amount: amount, price: price})
      when player == toPlayer do
    -1 * amount * price
  end

  def money_change(_player, _transaction) do
    0
  end

  @doc """
  Get the current money and product amount for a player, the start_value is a tuple with format {product, money}
  """
  def get_player_current_state(player, list_of_transactions, start_values) do
    Enum.reduce(list_of_transactions, start_values, fn transaction, {product, money} ->
      {product + product_change(player, transaction), money + money_change(player, transaction)}
    end)
  end
end
