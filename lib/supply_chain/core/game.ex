defmodule SupplyChain.Core.Game do
  alias SupplyChain.Core.{Player, Message, Transaction}
  defstruct [:players, :transactions, :messages, :roles, :factory, :round, :settings]

  def new(
        factory,
        roles,
        settings_override
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
    case find_player(game, name) do
      {game, nil} ->
        players = game.players
        {open_role, list_of_players} = Enum.min_by(players, fn {_, list} -> length(list) end)
        player = Player.new_player(name, open_role)
        new_list_of_players = [player | list_of_players]
        players = Map.put(players, open_role, new_list_of_players)
        {:ok, %__MODULE__{game | players: players}}

      {_, _} ->
        {:error, :name_already_used}
    end
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

  def send_message(game, type, buyer, seller, amount, save_fn \\ fn _message -> :ok end)

  def send_message(game, :buy, buyer, seller, amount, save_fn) do
    message = Message.new_buy(buyer, seller, amount)
    save_fn.(message)
    send_message(game, message)
  end

  def send_message(game, :offer, sender, amount, price, save_fn) do
    message = Message.new_offer(sender, amount, price)
    save_fn.(message)
    send_message(game, message)
  end

  def show_offers_for_role(game, role_name) when not is_map_key(game.players, role_name) do
    []
  end

  def show_offers_for_role(game, role_name) do
    {_, seller_role} = Enum.find(game.roles, fn {name, _} -> role_name == name end)

    players_with_role =
      if seller_role == "factory" do
        "factory"
      else
        Enum.map(game.players[seller_role], fn %{name: name} -> name end)
      end

    game.messages
    |> Enum.filter(fn
      %{type: :offer} -> true
      _ -> false
    end)
    |> filter_offers(players_with_role)
  end

  defp filter_offers(offers, player) when is_bitstring(player) do
    offers |> Enum.filter(fn %{from: from} -> from == player end)
  end

  defp filter_offers(offers, players) when is_list(players) do
    offers |> Enum.filter(fn %{from: from} -> Enum.member?(players, from) end)
  end

  def get_player_current_state(game, player) do
    Transaction.get_player_current_state(
      player,
      game.transactions,
      {game.settings[:starting_products], game.settings[:starting_money]}
    )
  end

  def find_player(game, name) do
    player =
      game.players
      |> Enum.flat_map(fn {_, player_list} -> player_list end)
      |> Enum.find(fn player -> player.name == name end)

    {game, player}
  end

  def change_role(%__MODULE__{round: round}, _, _) when round != 0 do
    {:error, :not_allowed}
  end

  def change_role(game, player_name, role_name) do
    case find_player(game, player_name) do
      {_, nil} ->
        {:error, :player_not_found}

      {_, %Player{role: old_role_name} = player} ->
        case Enum.find(game.roles, fn {name, _} -> name == role_name end) do
          nil ->
            {:error, :role_not_found}

          _ ->
            game = remove_player_from_role(game, player, old_role_name)

            updated_player = %Player{player | role: role_name}

            players = game.players

            players = Map.put(players, role_name, [updated_player | players[role_name]])

            {:ok,
             %__MODULE__{
               game
               | players: players
             }}
        end
    end
  end

  defp remove_player_from_role(
         %__MODULE__{players: players} = game,
         %Player{name: name},
         old_role_name
       ) do
    new_players =
      Enum.filter(players[old_role_name], fn %Player{name: player_name} -> name != player_name end)

    players = game.players

    players = Map.put(players, old_role_name, new_players)

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

  defp send_message(game, msg) do
    %__MODULE__{
      game
      | messages: [msg | game.messages]
    }
  end
end
