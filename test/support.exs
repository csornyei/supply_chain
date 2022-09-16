defmodule TestSupport do
  defmacro __using__(_options) do
    quote do
      alias SupplyChain.Core.{Transaction}
    end
  end
end
