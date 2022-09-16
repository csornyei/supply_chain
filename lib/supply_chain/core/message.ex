defmodule SupplyChain.Core.Message do
  alias SupplyChain.Core.Transaction

  @moduledoc """
    Messages are the way of communication between players
    There is two types of message:
      - offer, when a seller is offering products for a certain price
      - buy, which is a response to an offer with a price and an amount
  """
  defstruct [:type, :from, :to, :amount, :price, :time]

  def new_offer(from, amount, price) do
    %__MODULE__{
      type: :offer,
      from: from,
      to: nil,
      amount: amount,
      price: price,
      time: DateTime.utc_now()
    }
  end

  def new_buy(from, to, amount) do
    %__MODULE__{
      type: :buy,
      from: from,
      to: to,
      amount: amount,
      price: nil,
      time: DateTime.utc_now()
    }
  end

  defp reduce_messages_to_transactions(_message, {%{amount: offerAmount} = offer, list})
       when offerAmount == 0 do
    {offer, list}
  end

  defp reduce_messages_to_transactions(
         %{from: buyer, amount: buyAmount},
         {%{from: seller, amount: offerAmount, price: offerPrice}, list}
       )
       when offerAmount <= buyAmount do
    t = Transaction.new(from: seller, to: buyer, amount: offerAmount, price: offerPrice)
    {new_offer(seller, 0, offerPrice), [t | list]}
  end

  defp reduce_messages_to_transactions(
         %{from: buyer, amount: buyAmount},
         {%{from: seller, amount: offerAmount, price: offerPrice}, list}
       ) do
    t = Transaction.new(from: seller, to: buyer, amount: buyAmount, price: offerPrice)
    {new_offer(seller, offerAmount - buyAmount, offerPrice), [t | list]}
  end

  @doc """
    Create a list of transactions from an ordered and filtered list of messages.
    - The list need to be ordered as it works on first come first served basis.
    - It need to be filtered as well as it assumes the buy messages belongs to the offer message.
    - Finally the first message is an order message and the following are buy messages.
  """
  def create_transactions([head | tail]) do
    {_, list} = Enum.reduce(tail, {head, []}, &reduce_messages_to_transactions/2)
    list
  end

  defp add_message_to_seller(%{:type => :offer, from: seller} = message, acc)
       when not is_map_key(acc, seller) do
    Map.put(acc, seller, [message])
  end

  defp add_message_to_seller(%{:type => :buy, to: seller} = message, acc)
       when not is_map_key(acc, seller) do
    Map.put(acc, seller, [message])
  end

  defp add_message_to_seller(%{:type => :offer, from: seller} = message, acc) do
    Map.put(acc, seller, Map.fetch!(acc, seller) ++ [message])
  end

  defp add_message_to_seller(%{:type => :buy, to: seller} = message, acc) do
    Map.put(acc, seller, Map.fetch!(acc, seller) ++ [message])
  end

  @doc """
    Create a map of messages by sellers. The keys of the map is the creators of offer and the value is a list of messages where either the offer message `from` field is same as the key or the buy message `to` field is same as the key.
  """
  def collect_messages_to_sellers(message_list) do
    Enum.reduce(message_list, %{}, &add_message_to_seller/2)
  end

  defp split_on_offer(%{:type => :offer} = message, acc) do
    [[message] | acc]
  end

  defp split_on_offer(message, [first | tail]) do
    [first ++ [message] | tail]
  end

  @doc """
    Split a list of message. Expect the list to be sorted and from the same seller. The returned list start with an offer and the buy messages after that until the next offer
  """
  def split_messages_on_offer(message_list) do
    Enum.reduce(message_list, [], &split_on_offer/2)
  end

  def message_queue_to_transaction(message_queue) do
    message_queue
    |> collect_messages_to_sellers()
    |> Enum.map(fn {_, value} ->
      value
      |> Enum.sort(fn %{time: first_time}, %{time: second_time} ->
        first_time < second_time
      end)
    end)
    |> Enum.flat_map(&split_messages_on_offer/1)
    |> Enum.flat_map(&create_transactions/1)
  end
end
