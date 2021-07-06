defmodule Absinthe.Federation.Schema.Prototype do
  @moduledoc false

  use Absinthe.Schema.Prototype

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
