defmodule SpecItem do
  @type t :: %__MODULE__{
          id: String.t()
        }

  defstruct id: ""

  defimpl Absinthe.Federation.Schema.EntityUnion.Resolver do
    def resolve_type(_, _) do
      :spec_item
    end
  end
end
