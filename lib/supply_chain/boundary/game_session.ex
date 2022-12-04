defmodule SupplyChain.Boundary.GameSession do
  alias SupplyChain.Core.{Game}
  use GenServer, restart: :transient

  defstruct [:id, :game, :running, :idle_rounds]

  # API
  @doc """
    Let player join to the game with name

    iex> {:ok, name} = SupplyChain.Boundary.GameSession.new_game(factory: [{1,2}], roles: [{"test", "factory"}])
    iex> {:joined, player} = SupplyChain.Boundary.GameSession.join(name, "test_player")
    iex> player.name
    "test_player"
    iex> player.role
    "test"
  """
  def join(id, player_name) do
    GenServer.call(via(id), {:join, player_name})
  end

  @doc """
    Get offers for role
    iex> {:ok, name} = SupplyChain.Boundary.GameSession.new_game(factory: [{1,2}], roles: [{"test", "factory"}])
  """
  def get_offers_for_role(id, role_name) do
    GenServer.call(via(id), {:get_offers, role_name})
  end

  @doc """
    Get player current products and money
    iex> {:ok, name} = SupplyChain.Boundary.GameSession.new_game(factory: [{1,2}], roles: [{"test", "factory"}])
    iex> {:joined, player} = SupplyChain.Boundary.GameSession.join(name, "test_player")
  """
  def get_player_state(id, player_name) do
    GenServer.call(via(id), {:get_state, player_name})
  end

  @doc """
    Get messages in current round
    iex> {:ok, name} = SupplyChain.Boundary.GameSession.new_game(factory: [{1,2}], roles: [{"test", "factory"}])
    iex> {:joined, player} = SupplyChain.Boundary.GameSession.join(name, "test_player")
  """
  def get_messages(id) do
    GenServer.call(via(id), :get_messages)
  end

  @doc """
    Start new round
    iex> {:ok, name} = SupplyChain.Boundary.GameSession.new_game(factory: [{1,2}], roles: [{"test", "factory"}])
  """
  def next_round(id) do
    GenServer.cast(via(id), :next_round)
  end

  @doc """
    Send an offer message
    iex> {:ok, name} = SupplyChain.Boundary.GameSession.new_game(factory: [{1,2}], roles: [{"test", "factory"}])
    iex> {:joined, player} = SupplyChain.Boundary.GameSession.join(name, "test_player")
  """
  def send_offer_message(id, seller, amount, price) do
    GenServer.cast(via(id), {:offer, seller, amount, price})
  end

  @doc """
    Send a buy message
    iex> {:ok, name} = SupplyChain.Boundary.GameSession.new_game(factory: [{1,2}], roles: [{"test", "factory"}])
    iex> {:joined, player} = SupplyChain.Boundary.GameSession.join(name, "test_player")
  """
  def send_buy_message(id, buyer, seller, amount) do
    GenServer.call(via(id), {:buy, buyer, seller, amount})
  end

  @doc """
    Change player's role to `new_role` if player joined the game, role exists and it's still the 0th round

    Example:
    iex> {:ok, name} = SupplyChain.Boundary.GameSession.new_game(factory: [{1,2}], roles: [{"test1", "factory"}, {"test2", "test1"}])
    iex> {:joined, %{role: "test1"} = player} = SupplyChain.Boundary.GameSession.join(name, "test_player")
    iex> {:role_changed, %{name: "test_player", role: "test2"}} = SupplyChain.Boundary.GameSession.change_role(name, "test_player", "test2")
  """
  def change_role(id, name, new_role) do
    GenServer.call(via(id), {:change_role, name, new_role})
  end

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
    state = %SupplyChain.Boundary.GameSession{id: id, game: game, running: true, idle_rounds: 0}
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

  def handle_call({:change_role, name, role_name}, _from, %{game: game} = state) do
    case Game.change_role(game, name, role_name) do
      {:ok, game} ->
        {:reply, {:role_changed, Game.find_player(game, name) |> elem(1)},
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
      if new_state.idle_rounds >= 8 do
        {:stop, :normal, new_state}
      else
        new_state =
          if length(state.game.messages) < 2,
            do: %__MODULE__{new_state | idle_rounds: state.idle_rounds + 1}

        round_length = Keyword.fetch!(state.game.settings, :round_length)

        if round_length != -1 do
          GenServer.call(
            SupplyChain.Boundary.Timer.via(state.id),
            {:start_timer, round_length * 1000}
          )
        end

        {:noreply, new_state}
      end
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
