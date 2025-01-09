defmodule Example.EntityInterface.Rectangle do
  @type t :: %__MODULE__{
          id: String.t()
        }

  defstruct id: ""
end
