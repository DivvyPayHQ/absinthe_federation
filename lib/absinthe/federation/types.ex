defmodule Absinthe.Federation.Types do
  @moduledoc false

  use Absinthe.Schema.Notation

  @desc "The _Any scalar is used to pass representations of entities from external services into the root _entities field for execution."
  scalar :any, name: "_Any", open_ended: true do
    parse fn value -> {:ok, value} end
    serialize fn value -> value end
  end

  @desc """
  Schema composition at the gateway requires having each service's schema, annotated with its federation configuration.
  This information is fetched from each service using _service, an enhanced introspection entry point added to the
  query root of each federated service.
  """
  object :service, name: "_Service" do
    @desc """
    This SDL (schema definition language) is a printed version of the service's schema including the annotations of
    federation directives. This SDL does not include the additions of the federation spec.
    """
    field :sdl, :string
  end
end
