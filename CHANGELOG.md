# Changelog

## 0.8.0

- **BREAKING**: [Rename `:service` and `:any` type identifiers to avoid conflicts](https://github.com/DivvyPayHQ/absinthe_federation/pull/117)
  > This is a **breaking** change only if your code previously referenced the
  > Absinthe Federation type identifiers `:service` or `:any` directly.
  > For most users, there should be no impact.

## 0.7.1

- Bug Fix: [Support Absinthe batcher in EntitiesField](https://github.com/DivvyPayHQ/absinthe_federation/pull/114)

## 0.7.0

- Feature: [Support new federated directives](https://github.com/DivvyPayHQ/absinthe_federation/pull/109)
  - Progressive `@override`
  - `@authenticated`
  - `@context`
  - `@cost`
  - `@listSize`
  - `@policy`
  - `@requiresScopes`

## 0.6.1

- Bug Fix: [`@interfaceObject` entity resolution and SDL presence](https://github.com/DivvyPayHQ/absinthe_federation/pull/106)

## 0.6.0

- [Rework how entities field is resolved](https://github.com/DivvyPayHQ/absinthe_federation/pull/104):
  - Support async resolution with 0-arity function
  - Support Dataloader.Ecto
  - Support function capture in `_resolve_reference`

## 0.5.4

- Bug Fix: [Fix `@link` directive arguments](https://github.com/DivvyPayHQ/absinthe_federation/pull/101)

## 0.5.3

- Bug Fix: [Handle resolving `nil` for entity references](https://github.com/DivvyPayHQ/absinthe_federation/pull/98)

## 0.5.2

- Feature: [Support `@interfaceObject` directive](https://github.com/DivvyPayHQ/absinthe_federation/pull/96)

## 0.5.1

- Bug Fix: [Middleware unshim exception in entities field with persistent term schema](https://github.com/DivvyPayHQ/absinthe_federation/pull/94)

## 0.5.0

- Feature: [Support `@composeDirective`](https://github.com/DivvyPayHQ/absinthe_federation/pull/91)
- Bug Fix: [Import directive definitions when a custom prototype is used](https://github.com/DivvyPayHQ/absinthe_federation/pull/92)
- **BREAKING** (only if migrating from 0.4.2): Using a custom prototype will now
  require using the following method:

  ```elixir
  defmodule MyApp.MySchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema, prototype_schema: MyApp.MySchemaPrototype
  ```

  instead of

  ```elixir
  defmodule MyApp.MySchema do
    use Absinthe.Schema
    use Absinthe.Federation.Schema, skip_prototype: true
    @prototype_schema MyApp.MySchemaPrototype
  ```

## 0.4.2

- Feature: [Support using a custom schema prototype](https://github.com/DivvyPayHQ/absinthe_federation/pull/90)

## 0.4.1

- [Make the `@link` directive repeatable](https://github.com/DivvyPayHQ/absinthe_federation/pull/89)

## 0.4.0

- Feature: [Support Absinthe v1.7.2+ and Dataloader v2+](https://github.com/DivvyPayHQ/absinthe_federation/pull/87)
- **BREAKING**: `link/1` macro removed in favor of
  ["extend schema" method](README.md#federation-v2) (drop-in replacement).
- **BREAKING**: Now requires Absinthe v1.7 or above
- **BREAKING**: Now requires Elixir v1.12 or above

## 0.3.2

- Bug Fix: [Handle entity type names with multiple words](https://github.com/DivvyPayHQ/absinthe_federation/pull/68)

## 0.3.1

- [Add `@link` directive for importing directives](https://github.com/DivvyPayHQ/absinthe_federation/pull/62)

  > Previously, `import_sdl` was necessary to import Federation 2 directives.
  > The new `link` macro abstracts this and adds the `@link` directive according
  > to the spec. Please refer to the [README](README.md) for usage details.

## 0.3.0

- **BREAKING**: [Parent type for entities to have properly-cased keys](https://github.com/DivvyPayHQ/absinthe_federation/pull/59)

  > Previously, the entity resolvers had a parent map with atom keys that were
  > camelCased if the field name in the query was camelCased. With this version,
  > the parent type's keys will be converted to internal naming convention of
  > your Absinthe.Adapter, defaulting to snake_cased key names.
  >
  > You may need to update your extended type resolvers to receive parent type
  > maps with snake_cased keys.

- **BREAKING**: [@key directive to convert snake_cased field names to camelCased](https://github.com/DivvyPayHQ/absinthe_federation/pull/60)

  > Previously, the key_fields directive was used with camelCased field names,
  > such as `key_fields("someLongKeyName")`. This translated to
  > `@key(fields: "someLongKeyName")` in the schema. If the directive was added
  > with `key_fields("some_long_key_name")`, it translated to
  > `@key(fields: "some_long_key_name")` in the schema.
  >
  > With this version, adding snake_cased keys with this directive will be
  > converted to the external naming convention of your Absinthe.Adapter,
  > defaulting to camelCased field, such as
  > `key_fields("some_long_key_name")` resulting in
  > `@key(fields: "someLongKeyName")`.
  >
  > - If you were using the key_fields directive with camelCased field names,
  >   they may be refactored later since they will not be modified.
  > - If you were using it with snake_cased field names such as
  >   `key_fields("some_long_key_name")` you may need to make sure this change
  >   does not affect your schema.

## 0.2.53

- [Update directives to match @apollo/subgraph](https://github.com/DivvyPayHQ/absinthe_federation/pull/58)

## 0.2.52

- Feature: [Add Federation 2 directives](https://github.com/DivvyPayHQ/absinthe_federation/pull/56) (except for @link)

## 0.2.51

- Bug Fix: [Remove \_resolveReference field when rendering SDL](https://github.com/DivvyPayHQ/absinthe_federation/pull/55)

## 0.2.5

- [Disabled key field validation phases](https://github.com/DivvyPayHQ/absinthe_federation/pull/54) due to [errors for nullable key fields](https://github.com/DivvyPayHQ/absinthe_federation/issues/53)

## 0.2.4

- Bug Fix: [Composition error when there are no types for union \_Entity](https://github.com/DivvyPayHQ/absinthe_federation/pull/50)

## 0.2.3

- Bug Fix: [Non-referenced nested types stripped away](https://github.com/DivvyPayHQ/absinthe_federation/pull/48)

## 0.2.2

- Bug Fix: [Fix key field validation phases to work with camelCase SDL (#46)](https://github.com/DivvyPayHQ/absinthe_federation/pull/46)

## 0.2.1

- Bug Fix: Loosen absinthe version reqs to allow 1.7.0

## 0.2.0

- Bug Fix: [Remove federated types when rendering SDL](https://github.com/DivvyPayHQ/absinthe_federation/pull/42)
- Feature: [Support key fields validation when extending](https://github.com/DivvyPayHQ/absinthe_federation/pull/40)
- Bug Fix: [Preserve entity ordering](https://github.com/DivvyPayHQ/absinthe_federation/pull/37)
- Bug Fix: [Support key fields validation](https://github.com/DivvyPayHQ/absinthe_federation/pull/36)
- Bug Fix: [Fix duplicate resolvers](https://github.com/DivvyPayHQ/absinthe_federation/pull/35)

## 0.1.9

- Bug Fix: [Fix nested \_FieldSet atom conversion](https://github.com/DivvyPayHQ/absinthe_federation/pull/34)

## 0.1.8

- Bug Fix: [Fix duplicate resolvers](https://github.com/DivvyPayHQ/absinthe_federation/pull/35)

## 0.1.7

- Bug Fix: [Fix absinthe.federation.sdl task stripping out types](https://github.com/DivvyPayHQ/absinthe_federation/pull/31)

## 0.1.6

- Bug Fix: [Fix default \_resolve_reference bug](https://github.com/DivvyPayHQ/absinthe_federation/pull/30)

## 0.1.5

- Bug Fix: [Fix SDL render that was stripping out extended types](https://github.com/DivvyPayHQ/absinthe_federation/pull/29)

## 0.1.4

- Bug Fix: [Fix better error handling when the resolver is a dataloader](https://github.com/DivvyPayHQ/absinthe_federation/pull/27)

## 0.1.3

- Feature: [Improved \_Entity resolve_type](https://github.com/DivvyPayHQ/absinthe_federation/pull/26)

## 0.1.2

- Feature: [Support multiple @key directives on type](https://github.com/DivvyPayHQ/absinthe_federation/pull/24)

## 0.1.1

- Feature: [Support for dataloader and async middlewares](https://github.com/DivvyPayHQ/absinthe_federation/pull/16)
- Bug Fix: [Remove federated types from SDL render](https://github.com/DivvyPayHQ/absinthe_federation/pull/22)

## 0.1.0

- Feature: [Initial federation spec](https://github.com/DivvyPayHQ/absinthe_federation/pull/2)
- Feature: [Implement \_entities field resolution](https://github.com/DivvyPayHQ/absinthe_federation/pull/3)
- Bug Fix: [Fix representation default value](https://github.com/DivvyPayHQ/absinthe_federation/pull/4)
- Bug Fix: [Fix \_Any scalar missing parse/serialize](https://github.com/DivvyPayHQ/absinthe_federation/pull/5)
- Feature: [Add mix task to generate the schema SDL file](https://github.com/DivvyPayHQ/absinthe_federation/pull/7)
- Feature: [Use latest absinthe version](https://github.com/DivvyPayHQ/absinthe_federation/pull/13)
- Docs: [Added module documentation](https://github.com/DivvyPayHQ/absinthe_federation/pull/14)
