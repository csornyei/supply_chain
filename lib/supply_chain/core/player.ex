defmodule SupplyChain.Core.Player do
  defstruct [:name, :role]

  def new_player(name, role) do
    %__MODULE__{
      name: name,
      role: role
    }
  end
end
