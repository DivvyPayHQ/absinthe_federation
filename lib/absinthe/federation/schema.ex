defmodule Absinthe.Federation.Schema do
  @moduledoc """
  Module for injecting custom `Absinthe.Phase`s for adding federated types and directives.

  ## Example

      defmodule MyApp.MySchema do
        use Absinthe.Schema
      + use Absinthe.Federation.Schema

        query do
          ...
        end
      end
  """

  alias Absinthe.Phase.Schema.TypeImports
  alias Absinthe.Pipeline

  defmacro __using__(opts) do
    do_using(opts)
  end

  defp do_using(_opts) do
    quote do
      @pipeline_modifier unquote(__MODULE__)

      use Absinthe.Federation.Notation
      import_types Absinthe.Federation.Types

      # TODO: Move these to another module
      # Until we have `import_directives` we need to define these here
      # https://github.com/absinthe-graphql/absinthe/issues/1152
      @desc """
      _FieldSet is a custom scalar type that is used to represent a set of fields.
      Grammatically, a field set is a selection set minus the braces.
      This means it can represent a single field "upc", multiple fields "id countryCode",
      and even nested selection sets "id organization { id }"
      """
      scalar :_field_set, name: "_FieldSet" do
        serialize & &1
        parse &{:ok, &1}
      end

      @desc """
      The `@key` directive is used to indicate a combination of fields that can be used
      to uniquely identify and fetch an object or interface.
      """
      directive :key do
        arg :fields, non_null(:_field_set)
        on [:object, :interface]
      end

      @desc """
      The @external directive is used to mark a field as owned by another service.
      This allows service A to use fields from service B while also knowing at runtime the types of that field.
      """
      directive :external do
        on [:field_definition]
      end

      @desc """
      The @requires directive is used to annotate the required input fieldset from a base type for a resolver.
      It is used to develop a query plan where the required fields may not be needed by the client,
      but the service may need additional information from other services.
      """
      directive :requires do
        arg :fields, non_null(:_field_set)
        on [:field_definition]
      end

      @desc """
      The `@provides` directive is used to annotate the expected returned fieldset
      from a field on a base type that is guaranteed to be selectable by the gateway.
      """
      directive :provides do
        arg :fields, non_null(:_field_set)
        on [:field_definition]
      end

      directive :extends do
        on [:object, :interface]
      end
    end
  end

  @doc """
  Injects custom compile-time `Absinthe.Phase`
  """
  def pipeline(pipeline) do
    Pipeline.insert_after(pipeline, TypeImports, [
      __MODULE__.Phase.AddFederatedTypes,
      __MODULE__.Phase.AddFederatedDirectives,
      __MODULE__.Phase.Validation.KeyFieldsMustExist,
      __MODULE__.Phase.Validation.KeyFieldsMustBeValidWhenExtends
    ])
  end

  @spec remove_federated_types_pipeline(schema :: Absinthe.Schema.t()) :: Absinthe.Pipeline.t()
  def remove_federated_types_pipeline(schema) do
    schema
    |> Absinthe.Pipeline.for_schema(prototype_schema: schema.__absinthe_prototype_schema__())
    |> Absinthe.Pipeline.upto({Absinthe.Phase.Schema.Validation.Result, pass: :final})
    |> Absinthe.Schema.apply_modifiers(schema)

    # TODO: Due to an issue found with rendering the SDL we had to revert this functionality
    # https://github.com/DivvyPayHQ/absinthe_federation/issues/28
    # |> Absinthe.Pipeline.without(__MODULE__.Phase.AddFederatedTypes)
    # |> Absinthe.Pipeline.insert_before(
    #   Absinthe.Phase.Schema.ApplyDeclaration,
    #   __MODULE__.Phase.RemoveResolveReferenceFields
    # )
  end

  @spec to_federated_sdl(schema :: Absinthe.Schema.t()) :: String.t()
  def to_federated_sdl(schema) do
    pipeline = remove_federated_types_pipeline(schema)

    # we can be assertive here, since this same pipeline was already used to
    # successfully compile the schema.
    {:ok, bp, _} = Absinthe.Pipeline.run(schema.__absinthe_blueprint__(), pipeline)

    Absinthe.Schema.Notation.SDL.Render.inspect(bp, %{pretty: true})
  end
end
