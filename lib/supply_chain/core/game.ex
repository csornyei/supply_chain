defmodule SupplyChain.Core.Game do
  alias SupplyChain.Core.{Player, Message}
  defstruct [:players, :transactions, :messages, :factory, :round, :settings]

  def new(factory, role_names \\ ["wholesale", "retail"], settings_override \\ []) do
    players = Enum.reduce(role_names, %{}, fn role, players -> Map.put(players, role, []) end)

    %__MODULE__{
      players: players,
      transactions: [],
      messages: [],
      factory: factory,
      round: 0,
      settings:
        Keyword.merge(
          [
            starting_money: 1000,
            starting_products: 0,
            round_length: 120
          ],
          settings_override
        )
    }
  end

  def join(game, name) do
    players = game.players
    {open_role, list_of_players} = Enum.min_by(players, fn {_, list} -> length(list) end)
    player = Player.new_player(name, open_role)
    new_list_of_players = [player | list_of_players]
    players = Map.put(players, open_role, new_list_of_players)
    %__MODULE__{game | players: players}
  end

  defp get_next_round_starting_message(game)
       when is_list(game.factory) and game.round >= length(game.factory) do
    Message.new_offer("factory", 0, 0)
  end

  defp get_next_round_starting_message(game) when is_list(game.factory) do
    {offer_amount, offer_price} = Enum.at(game.factory, game.round)
    Message.new_offer("factory", offer_amount, offer_price)
  end

  defp get_next_round_starting_message(game) when is_function(game.factory) do
    {offer_amount, offer_price} = game.factory.()
    Message.new_offer("factory", offer_amount, offer_price)
  end

  def next_round(game) do
    transactions = Message.message_queue_to_transaction(game.messages)
    start_msg = get_next_round_starting_message(game)

    %__MODULE__{
      game
      | round: game.round + 1,
        messages: [start_msg],
        transactions: transactions ++ game.transactions
    }
  end
end
