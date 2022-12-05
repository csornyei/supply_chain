defmodule SupplyChain.Persistance.Message do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query, only: [from: 2]
  alias SupplyChain.Repo

  @message_fields ~w[game_id type from to amount price]a
  @timestamps ~w[inserted_at updated_at]a

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
    |> cast(fields, @message_fields ++ @timestamps)
    |> validate_required(@message_fields ++ @timestamps)
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
          price: message.price,
          inserted_at: message.timestamp,
          updated_at: message.timestamp
        }
        |> changeset()
        |> Repo.insert!()

        in_transaction.(message)
      end)

    result
  end
end
