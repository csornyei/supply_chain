defmodule SupplyChain.Boundary.GameSession do
  alias SupplyChain.Core.{Game}
  use GenServer, restart: :transient

  defstruct [:id, :game, :running]

  def init(args) do
    factory = Keyword.fetch!(args, :factory)
    roles = Keyword.get(args, :roles, [{"wholesale", "factory"}, {"retail", "wholesale"}])
    settings = Keyword.get(args, :settings, [])

    game = Game.new(factory, roles, settings)
    state = %SupplyChain.Boundary.GameSession{id: random_id(), game: game, running: true}
    {:ok, state}
  end

  defp random_id do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end

  def handle_call({:join, name}, _from, state) do
    case Game.join(state.game, name) do
      {:ok, game} ->
        {:reply, {:joined, Game.find_player(game, name) |> elem(1)},
         %SupplyChain.Boundary.GameSession{state | game: game}}

      {:error, msg} ->
        {:reply, {:error, msg}, state}
    end
  end

  def handle_call({:get_offers, role_name}, _from, state) do
    offers = Game.show_offers_for_role(state.game, role_name)
    {:reply, offers, state}
  end

  def handle_call({:get_state, name}, _from, state) do
    player_state = Game.get_player_current_state(state.game, name)
    {:reply, player_state, state}
  end

  def handle_call(:get_messages, _from, state) do
    {:reply, state.game.messages, state}
  end

  def handle_cast(:next_round, state) do
    game = Game.next_round(state.game)
    new_state = %SupplyChain.Boundary.GameSession{state | game: game}

    if is_list(game.factory) and game.round > length(game.factory) do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end

  def handle_cast({:offer, seller, amount, price}, state) do
    game = Game.send_message(state.game, :offer, seller, amount, price)
    {:noreply, %SupplyChain.Boundary.GameSession{state | game: game}}
  end

  def handle_cast({:buy, buyer, seller, amount}, state) do
    game = Game.send_message(state.game, :buy, buyer, seller, amount)
    {:noreply, %SupplyChain.Boundary.GameSession{state | game: game}}
  end
end
