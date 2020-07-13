    Maybge.getindex(xs, indices...) -> Some(x) or nothing

Try to get an item `x` at location specified by `indices` and return
`Some(x)` if found.  Return `nothing` if not found.

When `xs` is an array and `Maybge.getindex` is called inside
`@inbounds`, it always try to return `Some(x)` without checking the
bounds.

# Examples

```jldoctest
julia> using Maybe

julia> Maybe.getindex((11, 22, 33), 0)

julia> Maybe.getindex((11, 22, 33), 2)
Some(22)
```
