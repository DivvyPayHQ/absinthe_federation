defmodule Absinthe.Federation.Schema.Phase.Validation.KeyFieldsMustExistPhaseTest do
  use Absinthe.Federation.Case, async: true

  defmodule NullableIntermediateSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()
    end

    object :product_variation do
      field :product_uuid, non_null(:id)
    end

    object :product do
      key_fields("uuid variation { productUuid }")

      field :uuid, non_null(:id)
      field :variation, :product_variation
    end
  end

  defmodule CamelCaseIntermediateSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()
    end

    object :product_variation do
      field :product_uuid, non_null(:id)
    end

    object :product do
      key_fields("uuid productVariation { productUuid }")

      field :uuid, non_null(:id)
      field :product_variation, :product_variation
    end
  end

  defmodule DeepNestedMixedNullabilitySchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()
    end

    object :variation_change do
      field :change_name, :string
    end

    object :product_variation do
      field :id, non_null(:id)
      field :change, :variation_change
    end

    object :product do
      key_fields("uuid variation { id change { changeName } }")

      field :uuid, non_null(:id)
      field :variation, :product_variation
    end
  end

  defmodule ListIntermediateSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()
    end

    object :product_variation do
      field :product_uuid, non_null(:id)
    end

    object :product do
      key_fields("uuid variations { productUuid }")

      field :uuid, non_null(:id)
      field :variations, non_null(list_of(:product_variation))
    end
  end

  # Schemas that must fail validation are kept as strings and compiled inside the test, since the
  # KeyFieldsMustExist phase runs at compile time and would otherwise break this file's own
  # compilation.

  @interface_intermediate_schema """
  defmodule InterfaceIntermediateSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()
    end

    interface :node do
      field :id, non_null(:id)
      resolve_type(fn _object, _resolution -> nil end)
    end

    object :product do
      key_fields("uuid variation { id }")

      field :uuid, non_null(:id)
      field :variation, non_null(:node)
    end
  end
  """

  @union_intermediate_schema """
  defmodule UnionIntermediateSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()
    end

    object :product_variation do
      field :id, non_null(:id)
    end

    object :service_variation do
      field :id, non_null(:id)
    end

    union :variation_union do
      types([:product_variation, :service_variation])
      resolve_type(fn _object, _resolution -> nil end)
    end

    object :product do
      key_fields("uuid variation { id }")

      field :uuid, non_null(:id)
      field :variation, non_null(:variation_union)
    end
  end
  """

  @missing_intermediate_schema """
  defmodule MissingIntermediateSchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema

    query do
      extends()
    end

    object :product do
      key_fields("uuid missing { id }")

      field :uuid, non_null(:id)
    end
  end
  """

  test "accepts a bare nullable intermediate field" do
    assert Absinthe.Schema.to_sdl(NullableIntermediateSchema) =~ "@key(fields: \"uuid variation { productUuid }\")"
  end

  test "accepts a camelCase multi-word intermediate field" do
    assert Absinthe.Schema.to_sdl(CamelCaseIntermediateSchema) =~
             "@key(fields: \"uuid productVariation { productUuid }\")"
  end

  test "accepts deep nesting with mixed nullability" do
    assert Absinthe.Schema.to_sdl(DeepNestedMixedNullabilitySchema) =~
             "@key(fields: \"uuid variation { id change { changeName } }\")"
  end

  test "accepts a list-typed intermediate field" do
    assert Absinthe.Schema.to_sdl(ListIntermediateSchema) =~ "@key(fields: \"uuid variations { productUuid }\")"
  end

  test "rejects an interface-typed intermediate field" do
    error = ~r/The field \"variation\" of @key \"uuid variation { id }\" is an interface type/
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@interface_intermediate_schema) end)
  end

  test "rejects a union-typed intermediate field" do
    error = ~r/The field \"variation\" of @key \"uuid variation { id }\" is a union type/
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@union_intermediate_schema) end)
  end

  test "reports a missing intermediate field" do
    error = ~r/The object \"missing\" of @key \"uuid missing { id }\" does not exist./
    assert_raise(Absinthe.Schema.Error, error, fn -> Code.eval_string(@missing_intermediate_schema) end)
  end
end
