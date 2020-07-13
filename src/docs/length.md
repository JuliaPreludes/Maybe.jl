    Maybe.length(itr) -> Some(n::Integer) or nothing

Return the length of iterator if known.

# Examples

```jldoctest
julia> using Maybe

julia> Maybe.length(x for x in 1:3 if false)

julia> Maybe.length(1:3)
Some(3)
```
