defmodule TestSupport do
  defmacro __using__(_options) do
    quote do
      alias SupplyChain.Core.{Transaction, Message, Game, Player}
    end
  end
end
