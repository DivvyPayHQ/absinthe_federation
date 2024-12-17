defmodule ExampleItem do
  use Ecto.Schema

  schema "example_items" do
    field :item_id, :string
    timestamps(type: :utc_datetime)
  end
end
