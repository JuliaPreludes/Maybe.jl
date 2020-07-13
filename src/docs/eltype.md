    Maybe.eltype(itr) -> Some(T::Type) or nothing

Return the element type of iterator if known.

# Examples

```jldoctest
julia> using Maybe

julia> Maybe.eltype(x + 0 for x in 1:3)

julia> Maybe.eltype(1:0.1:3)
Some(Float64)
```
