defmodule SupplyChain.Repo.Migrations.CreateMessages do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add :game_id, :string, null: false
      add :type, :string, null: false
      add :from, :string, null: false
      add :to, :string
      add :amount, :integer, null: false
      add :price, :integer

      timestamps()
    end

    create index(:messages, :game_id)
  end
end
