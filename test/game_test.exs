defmodule GameTest do
  use ExUnit.Case
  use TestSupport

  describe "join" do
    setup do
      %{
        game:
          Game.new([], [
            {"first_role", "factory"},
            {"second_role", "first_role"},
            {"third_role", "second_role"}
          ])
      }
    end

    test "one player can join", %{game: game} do
      game = Game.join(game, "player1")
      assert length(game.players["first_role"]) == 1
      [first_role_player | _] = game.players["first_role"]
      assert first_role_player.name == "player1"
      assert first_role_player.role == "first_role"
    end

    test "one player can join for each role", %{game: game} do
      game = Game.join(game, "player1")
      game = Game.join(game, "player2")
      game = Game.join(game, "player3")
      assert length(game.players["first_role"]) == 1
      assert length(game.players["second_role"]) == 1
      assert length(game.players["third_role"]) == 1
    end

    test "more then one player can join for each role", %{game: game} do
      game = Game.join(game, "player1")
      game = Game.join(game, "player2")
      game = Game.join(game, "player3")
      game = Game.join(game, "player4")
      game = Game.join(game, "player5")
      assert length(game.players["first_role"]) == 2
      assert length(game.players["second_role"]) == 2
      [second_role_player | _] = game.players["second_role"]
      assert second_role_player.name == "player5"
      assert second_role_player.role == "second_role"
      assert length(game.players["third_role"]) == 1
    end
  end

  describe "next_round" do
    setup do
      %{
        game: Game.new([{1, 2}, {3, 4}, {5, 6}])
      }
    end

    test "increase round counter", %{game: game} do
      assert game.round == 0
      game = Game.next_round(game)
      assert game.round == 1
    end

    test "add correct message", %{game: game} do
      game = Game.next_round(game)
      msg = Enum.at(game.messages, 0)
      assert msg.from == "factory"
      assert msg.amount == 1
      assert msg.price == 2
    end

    test "add all correct message", %{game: game} do
      game = Game.next_round(game)
      game = Game.next_round(game)
      msg = Enum.at(game.messages, 0)
      assert msg.from == "factory"
      assert msg.amount == 3
      assert msg.price == 4
      game = Game.next_round(game)
      msg = Enum.at(game.messages, 0)
      assert msg.from == "factory"
      assert msg.amount == 5
      assert msg.price == 6
    end

    test "empty messages after final round", %{game: game} do
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)
      assert game.round == 6
      assert length(game.messages) == 1
      msg = Enum.at(game.messages, 0)
      assert msg.amount == 0
      assert msg.price == 0
    end

    test "create correct transactions", %{game: game} do
      game =
        Game.join(game, "player1")
        |> Game.next_round()
        |> Game.send_message(:buy, "player1", "factory", 5)
        |> Game.next_round()

      assert length(game.transactions) == 1
      t = Enum.at(game.transactions, 0)
      assert t.from == "factory"
      assert t.to == "player1"
      assert t.amount == 1
      assert t.price == 2
    end
  end

  describe "next_round function factory" do
    setup do
      %{
        game: Game.new(fn -> {1, 2} end)
      }
    end

    test "increase round counter", %{game: game} do
      assert game.round == 0
      game = Game.next_round(game)
      assert game.round == 1
    end

    test "add correct message", %{game: game} do
      game = Game.next_round(game)
      msg = Enum.at(game.messages, 0)
      assert msg.from == "factory"
      assert msg.amount == 1
      assert msg.price == 2
    end

    test "can called multiple times", %{game: game} do
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)
      game = Game.next_round(game)

      assert length(game.messages) == 1
      msg = Enum.at(game.messages, 0)
      assert msg.from == "factory"
      assert msg.amount == 1
      assert msg.price == 2
    end
  end

  describe "send_message" do
    setup %{} do
      game =
        Game.new([{10, 10}]) |> Game.join("player1") |> Game.join("player2") |> Game.next_round()

      %{
        game: game
      }
    end

    test "send offer message", %{game: game} do
      game = Game.send_message(game, :offer, "player1", 10, 15)
      assert length(game.messages) == 2
      msg = Enum.at(game.messages, 0)
      assert msg.from == "player1"
      assert msg.type == :offer
      assert msg.amount == 10
      assert msg.price == 15
    end

    test "send buy message", %{game: game} do
      game = Game.send_message(game, :buy, "player2", "player1", 10)
      assert length(game.messages) == 2
      msg = Enum.at(game.messages, 0)
      assert msg.from == "player2"
      assert msg.to == "player1"
      assert msg.type == :buy
      assert msg.amount == 10
    end
  end

  describe "show_offers_for_role" do
    setup %{} do
      game =
        Game.new([{10, 10}])
        |> Game.join("player1")
        |> Game.join("player2")
        |> Game.next_round()
        |> Game.send_message(:buy, "player2", "factory", 10)
        |> Game.send_message(:offer, "player2", 5, 15)

      %{
        game: game
      }
    end

    test "show offer to player1", %{game: game} do
      offers = Game.show_offers_for_role(game, "retail")
      assert length(offers) == 1
      offer = Enum.at(offers, 0)
      assert offer.from == "player2"
      assert offer.amount == 5
      assert offer.price == 15
    end

    test "show multiple offers", %{game: game} do
      offers =
        Game.send_message(game, :offer, "player2", 5, 30) |> Game.show_offers_for_role("retail")

      assert length(offers) == 2
      offer = Enum.at(offers, 0)
      assert offer.from == "player2"
      assert offer.amount == 5
      assert offer.price == 30
      offer = Enum.at(offers, 1)
      assert offer.from == "player2"
      assert offer.amount == 5
      assert offer.price == 15
    end
  end

  describe "get_player_current_state" do
    setup %{} do
      %{
        game: %Game{
          players: %{
            "retail" => [%Player{name: "player1", role: "retail"}],
            "wholesale" => [%Player{name: "player2", role: "wholesale"}]
          },
          transactions: [
            Transaction.new(from: "factory", to: "player2", amount: 10, price: 10),
            Transaction.new(from: "player2", to: "player1", amount: 10, price: 15),
            Transaction.new(from: "factory", to: "player2", amount: 10, price: 10),
            Transaction.new(from: "player2", to: "player1", amount: 10, price: 15),
            Transaction.new(from: "factory", to: "player2", amount: 10, price: 10),
            Transaction.new(from: "player2", to: "player1", amount: 5, price: 15),
            Transaction.new(from: "factory", to: "player2", amount: 10, price: 10),
            Transaction.new(from: "player2", to: "player1", amount: 5, price: 15),
            Transaction.new(from: "factory", to: "player2", amount: 10, price: 10),
            Transaction.new(from: "player2", to: "player1", amount: 5, price: 15),
            Transaction.new(from: "factory", to: "player2", amount: 10, price: 10),
            Transaction.new(from: "player2", to: "player1", amount: 5, price: 15)
          ],
          messages: [],
          roles: [{"wholesale", "factory"}, {"retail", "wholesale"}],
          factory: fn -> {10, 10} end,
          round: 10,
          settings: [starting_money: 1000, starting_products: 0]
        }
      }
    end

    test "get the correct state", %{game: game} do
      {product, money} = Game.get_player_current_state(game, "player1")
      assert product == 40
      assert money == 400
    end
  end
end
