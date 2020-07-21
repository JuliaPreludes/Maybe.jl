    Maybe.Extras.definite(x)

Unwrap `Some` recursively and obtain a non-`Some` value.  The returned
value is `nothing` if `x` is `nothing` or `nothing` wrapped in `Some`
(possibly multiple times).

# Examples
```julia
julia> using Maybe.Extras

julia> definite(Some(Some(Some(1))))
1

julia> definite(Some(Some(Some(nothing))))

julia> something(definite(Some(Some(nothing))), 2)
2
```
