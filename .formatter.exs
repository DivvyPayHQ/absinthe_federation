# Used by "mix format"

locals_without_parens = [entity: 1]

[
  locals_without_parens: locals_without_parens,
  inputs: ["{mix,.formatter}.exs", "{config,lib,test}/**/*.{ex,exs}"],
  line_length: 120,
  import_deps: [:absinthe],
  export: [
    locals_without_parens: locals_without_parens
  ]
]
