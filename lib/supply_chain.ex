defmodule SupplyChain do
  alias SupplyChain.Boundary.GameSession

  def start_game(args) do
    id = Keyword.get(args, :id, random_id())
    {:ok, pid} = GameSession.new_game(args ++ [id: id])
    {:ok, id, pid}
  end

  defp random_id do
    :crypto.strong_rand_bytes(6) |> Base.url_encode64(padding: false)
  end
end
