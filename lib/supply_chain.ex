defmodule SupplyChain do
  alias SupplyChain.Boundary.GameSession

  def start_game(args) do
    GameSession.new_game(args)
  end
end
