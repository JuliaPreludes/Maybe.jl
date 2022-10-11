    Maybe.Extras.asmissing(x)

Translate `Union{Nothing,T,Some{T},Some{Some{T}},...}` to
`Union{T,Missing}`.

This is a shorthand of `something(definite(x), missing)`.

# Examples
```julia
julia> using Maybe.Extras

julia> asmissing(1)
1

julia> asmissing(nothing)
missing

julia> asmissing(Some(Some(1)))
1

julia> asmissing(Some(Some(nothing)))
missing
```
