defmodule SpecItem do
  @type t :: %__MODULE__{
          item_id: String.t()
        }

  defstruct item_id: ""

  defimpl Absinthe.Federation.Schema.EntityUnion.Resolver do
    def resolve_type(_, _) do
      :spec_item
    end
  end
end
