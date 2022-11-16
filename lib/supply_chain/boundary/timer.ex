defmodule SupplyChain.Boundary.Timer do
  use GenServer, restart: :transient

  defstruct [:timerRef]

  def start_link(options \\ []) do
    id = Keyword.fetch!(options, :id)
    GenServer.start_link(__MODULE__, options, name: via(id))
  end

  def via(id) do
    {
      :via,
      Registry,
      {SupplyChain.Registry.GameSession, "#{id} timer worker"}
    }
  end

  def init(opts) do
    {:ok, opts}
  end

  def handle_call({:start_timer, time}, {pid, _}, state) do
    if !is_nil(state) and is_reference(state) do
      Process.cancel_timer(state)
    else
      IO.inspect(state)
    end

    timer_ref = Process.send_after(pid, :next_round, time)
    {:reply, nil, timer_ref}
  end
end
