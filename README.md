# Maybe.jl: Optional value handling for Julia

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://tkf.github.io/Maybe.jl/dev)
[![GitHub Actions](https://github.com/tkf/Maybe.jl/workflows/Run%20tests/badge.svg)](https://github.com/tkf/Maybe.jl/actions?query=workflow%3A%22Run+tests%22)

Maybe.jl provides functions and macros for handling the values of type
`Union{Some,Nothing}`; i.e., _option type_.  The main entry point for
the optional value handling is the macro `@?`:

```julia
julia> using Maybe

julia> data = [1, 3, 2, 1];

julia> @? data[findfirst(iseven, data)]
Some(2)

julia> y = @? data[findfirst(>=(4), data)]

julia> @assert y === nothing
```

Maybe.jl also provides low-level functions such as `Maybe.get` which
is the "Maybe" variant of `Base.get`:

```julia
julia> Maybe.get(Dict(:a => 1), :a)
Some(1)

julia> @assert Maybe.get(Dict(:a => 1), :b) === nothing
```

See more in the [documentation](https://tkf.github.io/Maybe.jl/dev).
