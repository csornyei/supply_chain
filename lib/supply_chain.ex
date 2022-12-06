defmodule SupplyChain do
  alias SupplyChain.Boundary.GameSession

  def start_game(args) do
    id = Keyword.get(args, :id, random_id())
    {:ok, pid} = GameSession.new_game(args ++ [id: id])
    {:ok, id, pid}
  end

  def join(id, player_name) do
    GameSession.join(id, player_name)
  end

  def change_role(id, player_name, role_name) do
    GameSession.change_role(id, player_name, role_name)
  end

  def get_offers_for_role(id, role_name) do
    GameSession.get_offers_for_role(id, role_name)
  end

  def get_player_state(id, player_name) do
    GameSession.get_player_state(id, player_name)
  end

  def get_messages(id) do
    GameSession.get_messages(id)
  end

  def next_round(id) do
    GameSession.next_round(id)
  end

  def send_offer_message(id, seller, amount, price) do
    GameSession.send_offer_message(id, seller, amount, price)
  end

  def send_buy_message(id, buyer, seller, amount) do
    GameSession.send_buy_message(id, buyer, seller, amount)
  end

  defp random_id do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end
end
