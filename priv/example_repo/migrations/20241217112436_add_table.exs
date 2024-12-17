defmodule ExampleRepo.Migrations.AddTable do
  use Ecto.Migration

  def change do
    create table(:example_items) do
      add :item_id, :string, null: false
      timestamps(type: :utc_datetime)
    end
  end
end
