defmodule Absinthe.Federation.Schema.Prototype.FederatedDirectives do
  @moduledoc false

  defmacro __using__(_) do
    quote do
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

      scalar :federation_scope, name: "federation__Scope" do
        serialize & &1
        parse &{:ok, &1}
      end

      scalar :federation_policy, name: "federation__Policy" do
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
        arg :import, list_of(:link_import)
        repeatable true
        on [:schema]
      end

      @desc """
      The @requiresScopes directive marks fields and types as restricted based on required scopes.
      The directive includes a scopes argument with an array of the required scopes to declare which scopes are required.
      """
      directive :requires_scopes do
        arg :scopes, non_null(list_of(non_null(list_of(non_null(:federation_scope)))))

        on [:field_definition, :object, :interface, :scalar, :enum]
      end

      @desc """
      The @authenticated directive marks specific fields and types as requiring authentication.
      It works by checking for the apollo::authentication::jwt_claims key in a request's context,
      that is added either by the JWT authentication plugin, when the request contains a valid JWT,
      or by an authentication coprocessor. If the key exists, it means the request is authenticated,
      and the router executes the query in its entirety. If the request is unauthenticated, the router
      removes @authenticated fields before planning the query and only executes the parts of the query
      that don't require authentication.
      """
      directive :authenticated do
        arg :scopes, non_null(list_of(non_null(list_of(non_null(:federation_scope)))))

        on [:field_definition, :object, :interface, :scalar, :enum]
      end

      @desc """
      The @policy directive marks fields and types as restricted based on authorization policies evaluated in a [Rhai script](https://www.apollographql.com/docs/graphos/routing/customization/rhai/) or
      [coprocessor](https://www.apollographql.com/docs/router/customizations/coprocessor). This enables custom authorization validation beyond authentication and scopes. It is useful when we need more complex policy evaluation
      than verifying the presence of a claim value in a list (example: checking specific values in headers).
      """
      directive :policy do
        arg :policies, non_null(list_of(non_null(list_of(non_null(:federation_policy)))))

        on [:field_definition, :object, :interface, :scalar, :enum]
      end

      @desc """
      The @context directive defines a named context from which a field of the annotated type can be passed to a receiver of the context.
      The receiver must be a field annotated with the @fromContext directive.  
      """
      directive :context do
        arg :name, non_null(:string)

        on [:object, :interface, :union]
      end

      @desc """
      The @listSize directive is used to customize the cost calculation of the demand control feature of GraphOS Router.

      In the static analysis phase, the cost calculator does not know how many entities will be returned by each list field in a given query.
      By providing an estimated list size for a field with @listSize, the cost calculator can produce a more accurate estimate of the cost during static analysis.  
      """
      directive :list_size do
        arg :assumed_size, :integer
        arg :slicing_arguments, list_of(non_null(:string))
        arg :sized_fields, list_of(non_null(:string))
        arg :required_one_slicing_argument, :boolean, default_value: true

        on [:field_definition]
      end

      @desc """
      The @cost directive defines a custom weight for a schema location. For GraphOS Router, it customizes the operation cost calculation of the demand control feature.

      If @cost is not specified for a field, a default value is used:

        - Scalars and enums have default cost of 0
        - Composite input and output types have default cost of 1

      Regardless of whether @cost is specified on a field, the field cost for that field also accounts for its arguments and selections.  
      """
      directive :cost do
        arg :weight, non_null(:integer)

        on [:argument_definition, :enum, :field_definition, :input_field_definition, :object, :scalar]
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

      The progressive @override feature enables the gradual, progressive deployment of a subgraph with an @override field.
      As a subgraph developer, you can customize the percentage of traffic that the overriding and overridden subgraphs each resolve for a field.

      see [Apollo Federation docs](https://www.apollographql.com/docs/graphos/schema-design/federated-schemas/reference/directives#progressive-override)
      for details.
      """
      directive :override do
        arg :from, non_null(:string)
        arg :label, :string

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
      Indicates that an object definition serves as an abstraction of another subgraph's entity interface.
      This abstraction enables a subgraph to automatically contribute fields to all entities that implement
      a particular entity interface.
      """
      directive :interface_object do
        on [:object]
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

      @desc """
      Indicates to composition that all uses of a particular custom type system directive in the subgraph schema should
      be preserved in the supergraph schema.

      See [Apollo Federation docs](https://www.apollographql.com/docs/federation/federated-types/federated-directives/#managing-custom-directives)
      for details.
      """
      directive :compose_directive do
        arg :name, non_null(:string)
        repeatable true
        on [:schema]
      end
    end
  end
end
