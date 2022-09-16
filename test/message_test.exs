defmodule MessageTest do
  use ExUnit.Case
  use TestSupport
  doctest SupplyChain.Core.Message, import: true

  describe "create_transactions" do
    setup do
      %{
        messages: [
          Message.new_offer("player1", 15, 15),
          Message.new_buy("player2", "player1", 5),
          Message.new_buy("player3", "player1", 10),
          Message.new_buy("player4", "player1", 15)
        ]
      }
    end

    test "list has length of 2", %{messages: messages} do
      transactions = Message.create_transactions(messages)
      assert length(transactions) == 2
    end

    test "first transaction is correct", %{messages: messages} do
      [first | _] = Message.create_transactions(messages)
      assert first.from == "player1"
      assert first.to == "player3"
      assert first.amount == 10
      assert first.price == 15
    end

    test "second transaction is correct", %{messages: messages} do
      [_ | [second]] = Message.create_transactions(messages)
      assert second.from == "player1"
      assert second.to == "player2"
      assert second.amount == 5
      assert second.price == 15
    end
  end

  describe "collect_messages_to_sellers" do
    setup do
      %{
        messages: [
          Message.new_offer("player1", 15, 15),
          Message.new_buy("player2", "player1", 5),
          Message.new_buy("player3", "player1", 10),
          Message.new_buy("player4", "player1", 15),
          Message.new_offer("player2", 5, 20),
          Message.new_buy("player5", "player2", 5),
          Message.new_buy("player3", "player2", 10)
        ]
      }
    end

    test "returns a map", %{messages: messages} do
      collected_messages = Message.collect_messages_to_sellers(messages)
      assert is_map(collected_messages)
    end

    test "has field for each player with offer", %{messages: messages} do
      collected_messages = Message.collect_messages_to_sellers(messages)
      {:ok, _} = Map.fetch(collected_messages, "player1")
      {:ok, _} = Map.fetch(collected_messages, "player2")
    end

    test "the fields has correct length", %{messages: messages} do
      collected_messages = Message.collect_messages_to_sellers(messages)
      {:ok, player1_messages} = Map.fetch(collected_messages, "player1")
      assert length(player1_messages) == 4
      {:ok, player2_messages} = Map.fetch(collected_messages, "player2")
      assert length(player2_messages) == 3
    end
  end
end
