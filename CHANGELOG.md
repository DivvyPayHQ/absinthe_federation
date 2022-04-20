# Changelog

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
