    Maybe.first(xs) -> Some(x) or nothing

Try to get the first item `x` in the container `xs` and return
`Some(x)` if exists.  Return `nothing` if `xs` is empty.

# Examples

```jldoctest
julia> using Maybe

julia> Maybe.first([])

julia> Maybe.first([1])
Some(1)
```
