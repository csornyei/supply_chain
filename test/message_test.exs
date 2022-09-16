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

  describe "split_messages_on_offer" do
    setup do
      %{
        messages: [
          Message.new_offer("player1", 15, 15),
          Message.new_buy("player2", "player1", 5),
          Message.new_buy("player3", "player1", 10),
          Message.new_buy("player4", "player1", 15),
          Message.new_offer("player1", 5, 20),
          Message.new_buy("player5", "player1", 5),
          Message.new_buy("player3", "player1", 10)
        ]
      }
    end

    test "returns a list", %{messages: messages} do
      splitted = Message.split_messages_on_offer(messages)
      assert is_list(splitted)
    end

    test "the list has correct length", %{messages: messages} do
      splitted = Message.split_messages_on_offer(messages)
      assert length(splitted) == 2
    end

    test "the elements are also lists with correct lengths", %{messages: messages} do
      [first | [second]] = Message.split_messages_on_offer(messages)
      assert is_list(first)
      assert length(first) == 3
      assert is_list(second)
      assert length(second) == 4
    end

    test "first element in each list is offer", %{messages: messages} do
      [first | [second]] = Message.split_messages_on_offer(messages)
      [%{:type => :offer} | _] = first
      [%{:type => :offer} | _] = second
    end
  end

  describe "message_queue_to_transaction" do
    setup do
      %{
        messages: [
          %Message{
            type: :offer,
            from: "player1",
            amount: 50,
            price: 10,
            time: ~N[2022-09-16 10:00:00]
          },
          %Message{
            type: :offer,
            from: "player2",
            amount: 20,
            price: 15,
            time: ~N[2022-09-16 10:10:00]
          },
          %Message{
            type: :buy,
            from: "player2",
            to: "player1",
            amount: 20,
            time: ~N[2022-09-16 10:20:00]
          },
          %Message{
            type: :buy,
            from: "player3",
            to: "player1",
            amount: 35,
            time: ~N[2022-09-16 10:30:00]
          },
          %Message{
            type: :buy,
            from: "player4",
            to: "player2",
            amount: 15,
            time: ~N[2022-09-16 10:40:00]
          },
          %Message{
            type: :buy,
            from: "player5",
            to: "player2",
            amount: 20,
            time: ~N[2022-09-16 10:50:00]
          },
          %Message{
            type: :offer,
            from: "player1",
            amount: 15,
            price: 15,
            time: ~N[2022-09-16 11:00:00]
          },
          %Message{
            type: :offer,
            from: "player3",
            amount: 30,
            price: 30,
            time: ~N[2022-09-16 11:10:00]
          },
          %Message{
            type: :buy,
            from: "player2",
            to: "player1",
            amount: 15,
            time: ~N[2022-09-16 11:20:00]
          },
          %Message{
            type: :buy,
            from: "player3",
            to: "player1",
            amount: 10,
            time: ~N[2022-09-16 11:30:00]
          },
          %Message{
            type: :buy,
            from: "player4",
            to: "player3",
            amount: 10,
            time: ~N[2022-09-16 11:40:00]
          },
          %Message{
            type: :buy,
            from: "player5",
            to: "player3",
            amount: 10,
            time: ~N[2022-09-16 11:50:00]
          }
        ]
      }
    end

    test "returns a list", %{messages: messages} do
      transactions = Message.message_queue_to_transaction(messages)
      assert is_list(transactions)
    end

    test "it has correct length", %{messages: messages} do
      transactions = Message.message_queue_to_transaction(messages)
      assert length(transactions) == 7
    end

    test "all elements are transaction", %{messages: messages} do
      transactions = Message.message_queue_to_transaction(messages)
      assert Enum.all?(transactions, &(&1.__struct__ == SupplyChain.Core.Transaction))
    end
  end
end
