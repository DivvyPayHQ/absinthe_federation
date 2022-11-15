defmodule Absinthe.Federation.Schema.DirectiveTest do
  use Absinthe.Federation.Case, async: true

  alias Absinthe.Adapter.{LanguageConventions, Passthrough, Underscore}
  alias Absinthe.Blueprint.Directive, as: BlueprintDirective
  alias Absinthe.Blueprint.Input.Argument
  alias Absinthe.Blueprint.Input.RawValue
  alias Absinthe.Blueprint.Input.String
  alias Absinthe.Federation.Schema.Directive

  test "builds directive with name" do
    name = "extends"

    directive = Directive.build(name, nil)
    assert %BlueprintDirective{name: ^name} = directive
  end

  test "builds directive without args" do
    %{arguments: arguments} = Directive.build("extends", nil)
    assert Enum.empty?(arguments)
  end

  test "builds directive with args" do
    assert %BlueprintDirective{arguments: [argument]} = Directive.build("key", nil, fields: "id")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "id"
               }
             }
           } = argument
  end

  test "builds @key directive with properly cased value" do
    assert %BlueprintDirective{arguments: [argument]} = Directive.build("key", nil, fields: "some_cased_key")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "someCasedKey"
               }
             }
           } = argument

    assert %BlueprintDirective{arguments: [argument]} = Directive.build("key", nil, fields: "someCasedKey")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "someCasedKey"
               }
             }
           } = argument

    assert %BlueprintDirective{arguments: [argument]} =
             Directive.build("key", nil, fields: "some_cased_key { another_cased_key }")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "someCasedKey { anotherCasedKey }"
               }
             }
           } = argument

    assert %BlueprintDirective{arguments: [argument]} =
             Directive.build("key", nil, fields: "someCasedKey { anotherCasedKey }")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "someCasedKey { anotherCasedKey }"
               }
             }
           } = argument
  end

  test "builds directive with properly cased name by default" do
    assert %BlueprintDirective{name: "composeDirective"} =
             Directive.build("compose_directive", nil, name: "@myDirective")
  end

  test "builds directive with custom absinthe adapters" do
    assert %BlueprintDirective{name: "composeDirective"} =
             Directive.build("compose_directive", LanguageConventions, name: "@myDirective")

    assert %BlueprintDirective{name: "compose_directive"} =
             Directive.build("compose_directive", Passthrough, name: "@myDirective")

    assert %BlueprintDirective{name: "compose_directive"} =
             Directive.build("compose_directive", Underscore, name: "@myDirective")
  end
end
