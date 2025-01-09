defmodule Example.EntityInterface.Circle do
  @type t :: %__MODULE__{
          id: String.t()
        }

  defstruct id: ""
end
