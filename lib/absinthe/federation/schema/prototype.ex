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

  enum :link_purpose, name: "link__Purpose" do
    value :security
    value :execution
  end

  scalar :link_import, name: "link__Import" do
    serialize & &1
    parse &{:ok, &1}
  end

  @desc """
  The `@key` directive is used to indicate a combination of fields that can be used
  to uniquely identify and fetch an object or interface.
  """
  directive :key do
    arg :fields, non_null(:_field_set)
    arg :resolvable, :boolean, default_value: true
    repeatable true
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

  @desc """
  The `@link` directive links definitions within the document to external schemas.
  """
  directive :link do
    arg :url, :string
    arg :as, :string
    arg :for, :link_purpose
    arg :import, :link_import
    repeatable true
    on [:schema]
  end

  @desc """
  The `@shareable` directive is used to indicate that a field can be resolved by multiple subgraphs.
  Any subgraph that includes a shareable field can potentially resolve a query for that field.
  To successfully compose, a field must have the same shareability mode (either shareable or non-shareable)
  across all subgraphs.
  """
  directive :shareable do
    on [:field_definition, :object]
  end

  @desc """
  The `@override` directive is used to indicate that the current subgraph is
  taking responsibility for resolving the marked field away from
  the subgraph specified in the from argument.
  """
  directive :override do
    arg :from, non_null(:string)

    on [:field_definition]
  end

  @desc """
  The `@inaccessible` directive indicates that a field or type should be omitted from the gateway's API schema,
  even if the field is also defined in other subgraphs.
  """
  directive :inaccessible do
    on [
      :field_definition,
      :object,
      :interface,
      :union,
      :argument_definition,
      :scalar,
      :enum,
      :enum_value,
      :input_object,
      :input_field_definition
    ]
  end

  @desc """
  The `@tag` directive indicates whether to include or exclude the field/type from your contract schema.
  """
  directive :tag do
    arg :name, non_null(:string)

    repeatable true

    on [
      :field_definition,
      :object,
      :interface,
      :union,
      :argument_definition,
      :scalar,
      :enum,
      :enum_value,
      :input_object,
      :input_field_definition
    ]
  end
end
