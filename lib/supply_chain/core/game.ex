defmodule SupplyChain.Core.Game do
  alias SupplyChain.Core.{Player, Message, Transaction}
  defstruct [:players, :transactions, :messages, :roles, :factory, :round, :settings]

  def new(
        factory,
        roles \\ [{"wholesale", "factory"}, {"retail", "wholesale"}],
        settings_override \\ []
      ) do
    players = Enum.reduce(roles, %{}, fn {role, _}, players -> Map.put(players, role, []) end)

    %__MODULE__{
      players: players,
      transactions: [],
      messages: [],
      roles: roles,
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
    transactions = Message.message_queue_to_transaction(Enum.reverse(game.messages))
    start_msg = get_next_round_starting_message(game)

    %__MODULE__{
      game
      | round: game.round + 1,
        messages: [start_msg],
        transactions: transactions ++ game.transactions
    }
  end

  def send_message(game, :buy, buyer, seller, amount) do
    send_message(game, Message.new_buy(buyer, seller, amount))
  end

  def send_message(game, :offer, sender, amount, price) do
    send_message(game, Message.new_offer(sender, amount, price))
  end

  defp send_message(game, msg) do
    %__MODULE__{
      game
      | messages: [msg | game.messages]
    }
  end

  def show_offers_for_role(game, role_name) do
    {_, seller_role} = Enum.find(game.roles, fn {name, _} -> role_name == name end)
    players_with_role = Enum.map(game.players[seller_role], fn %{name: name} -> name end)

    game.messages
    |> Enum.filter(fn
      %{type: :offer} -> true
      _ -> false
    end)
    |> Enum.filter(fn %{from: from} -> Enum.member?(players_with_role, from) end)
  end

  def get_player_current_state(game, player) do
    Transaction.get_player_current_state(
      player,
      game.transactions,
      {game.settings[:starting_products], game.settings[:starting_money]}
    )
  end
end
