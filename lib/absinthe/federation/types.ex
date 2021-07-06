defmodule Absinthe.Federation.Types do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "The _Any scalar is used to pass representations of entities from external services into the root _entities field for execution."
  scalar :any, name: "_Any"

  object :service, name: "_Service" do
    field :sdl, :string
  end
end
