defmodule SpecItem do
  @type t :: %__MODULE__{
          item_id: String.t()
        }

  defstruct item_id: ""

  defimpl Absinthe.Federation.Schema.EntityUnion.Resolver do
    def resolve_type(_, _), do: :spec_item
  end
end

defmodule SpecItem.Loader do
  def data, do: Dataloader.KV.new(&load/2)

  def load(_, ids) do
    ids
    |> Map.new(fn id ->
      case id do
        "3" -> {id, {:error, "Failed getting spec item with id: #{id}"}}
        _ -> {id, {:ok, %SpecItem{item_id: id}}}
      end
    end)
  end
end
