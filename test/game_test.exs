defmodule GameTest do
  use ExUnit.Case
  use TestSupport

  describe "join" do
    setup do
      %{
        game: Game.new([], ["first_role", "second_role", "third_role"])
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
end
