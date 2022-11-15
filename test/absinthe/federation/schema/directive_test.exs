defmodule Absinthe.Federation.Schema.DirectiveTest do
  use Absinthe.Federation.Case, async: true

  alias Absinthe.Blueprint.Directive, as: BlueprintDirective
  alias Absinthe.Blueprint.Input.Argument
  alias Absinthe.Blueprint.Input.RawValue
  alias Absinthe.Blueprint.Input.String
  alias Absinthe.Federation.Schema.Directive

  test "builds directive with name" do
    name = "extends"

    directive = Directive.build(name)
    assert %BlueprintDirective{name: ^name} = directive
  end

  test "builds directive without args" do
    %{arguments: arguments} = Directive.build("extends")
    assert Enum.empty?(arguments)
  end

  test "builds directive with args" do
    assert %BlueprintDirective{arguments: [argument]} = Directive.build("key", fields: "id")

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
    assert %BlueprintDirective{arguments: [argument]} = Directive.build("key", fields: "some_cased_key")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "someCasedKey"
               }
             }
           } = argument

    assert %BlueprintDirective{arguments: [argument]} = Directive.build("key", fields: "someCasedKey")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "someCasedKey"
               }
             }
           } = argument

    assert %BlueprintDirective{arguments: [argument]} =
             Directive.build("key", fields: "some_cased_key { another_cased_key }")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "someCasedKey { anotherCasedKey }"
               }
             }
           } = argument

    assert %BlueprintDirective{arguments: [argument]} =
             Directive.build("key", fields: "someCasedKey { anotherCasedKey }")

    assert %Argument{
             name: "fields",
             input_value: %RawValue{
               content: %String{
                 value: "someCasedKey { anotherCasedKey }"
               }
             }
           } = argument
  end

  test "builds directive with properly cased name" do
    assert %BlueprintDirective{name: "composeDirective"} = Directive.build("compose_directive", name: "@myDirective")
  end
end
