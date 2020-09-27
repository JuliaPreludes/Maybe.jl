    Maybe.last(xs) -> Some(x) or nothing

Try to get the last item `x` in the container `xs` and return
`Some(x)` if exists.  Return `nothing` if `xs` is empty.

# Examples

```jldoctest
julia> using Maybe

julia> Maybe.last([])

julia> Maybe.last([1])
Some(1)
```
