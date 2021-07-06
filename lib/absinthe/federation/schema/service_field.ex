defmodule Absinthe.Federation.Schema.ServiceField do
  @moduledoc false

  alias Absinthe.Blueprint.Schema.FieldDefinition
  alias Absinthe.Blueprint.TypeReference.NonNull
  alias Absinthe.Schema
  alias Absinthe.Schema.Notation

  def build() do
    %FieldDefinition{
      __reference__: Notation.build_reference(__ENV__),
      description: """
      The _service field on the query root returns SDL
      which includes all of the service's types (after any non-federation transforms),
      as well as federation directive annotations on the fields and types.
      The federation schema modifications (i.e. new types and directive definitions)
      should not be included in this SDL.
      """,
      identifier: :_service,
      module: __MODULE__,
      name: "_service",
      type: %NonNull{
        of_type: :service
      },
      middleware: [{Absinthe.Resolution, &__MODULE__.resolver/3}]
    }
  end

  def resolver(_parent, _args, %{schema: schema} = _resolution) do
    {:ok, %{sdl: Schema.to_sdl(schema)}}
  end
end
