defmodule SupplyChain.Persistance.Message do
  use Ecto.Schema
  import Ecto.Changeset
  alias SupplyChain.Repo

  @required_fields ~w[game_id type from amount]a
  @message_fields ~w[to price]a

  schema "messages" do
    field(:game_id, :string)
    field(:type, :string)
    field(:from, :string)
    field(:to, :string)
    field(:amount, :integer)
    field(:price, :integer)

    timestamps()
  end

  def changeset(fields) do
    %__MODULE__{}
    |> cast(fields, @message_fields ++ @required_fields)
    |> validate_required(@required_fields)
  end

  def save_message(game_id, message, in_transaction \\ fn _message -> :ok end) do
    {:ok, result} =
      Repo.transaction(fn ->
        %{
          game_id: game_id,
          type: to_string(message.type),
          from: message.from,
          to: message.to,
          amount: message.amount,
          price: message.price
        }
        |> IO.inspect()
        |> changeset()
        |> IO.inspect()
        |> Repo.insert!()

        in_transaction.(message)
      end)

    result
  end
end
