# Used by "mix format"
locals_without_parens = [
  extend: 1,
  extend: 2,
  external: 0,
  external: 1,
  external: 2,
]

[
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120,
  locals_without_parens: locals_without_parens,
  export: [
    locals_without_parens: locals_without_parens
  ]
  import_deps: [:absinthe]
]
