defmodule SupplyChain.Boundary.GameSession do
  alias SupplyChain.Core.{Game}
  use GenServer, restart: :transient

  defstruct [:id, :game, :running]

  defstruct [:game, :running]

  def start_link(args) do
    id = random_id()

    GenServer.start_link(
      __MODULE__,
      args ++ [id: id],
      name: via(id)
    )
  end

  def via(id) do
    {
      :via,
      Registry,
      {SupplyChain.Registry.GameSession, id}
    }
  end

  def new_game(args) do
    {:ok, pid} =
    DynamicSupervisor.start_child(
      SupplyChain.Supervisor.GameSession,
      {__MODULE__, args}
    )

    name = GenServer.call(pid, :id)
    {:ok, name}
  end

  def init(args) do
    id = Keyword.fetch!(args, :id)
    factory = Keyword.fetch!(args, :factory)
    roles = Keyword.get(args, :roles, [{"wholesale", "factory"}, {"retail", "wholesale"}])
    settings = Keyword.get(args, :settings, [])

    game = Game.new(factory, roles, settings)
    state = %SupplyChain.Boundary.GameSession{id: id, game: game, running: true}
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

  def handle_call(:id, _from, state) do
    {:reply, state.id, state}
  end

  def handle_info(:next_round, state) do
    GenServer.cast(self(), :next_round)
    {:noreply, state}
  end

  def handle_cast(:next_round, state) do
    game = Game.next_round(state.game)
    new_state = %SupplyChain.Boundary.GameSession{state | game: game}

    if game.round == 1 do
      DynamicSupervisor.start_child(
        SupplyChain.Supervisor.GameSession,
        {SupplyChain.Boundary.Timer, id: state.id}
      )
    end

    if is_list(game.factory) and game.round > length(game.factory) do
      {:stop, :normal, new_state}
    else
      round_length = Keyword.fetch!(state.game.settings, :round_length)

      GenServer.call(
        SupplyChain.Boundary.Timer.via(state.id),
        {:start_timer, round_length * 1000}
      )

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

  def terminate(_, state) do
    GenServer.stop(SupplyChain.Boundary.Timer.via(state.id), :normal)
  end
end
