    Maybe.Extras.defaultto(x)

A shorthand of [`ifnothing(() -> x)`](@ref Maybe.Extras.ifnothing).

# Examples

```jldoctest
julia> using Maybe.Extras

julia> Some(1) |> defaultto(:fallback)
1

julia> nothing |> defaultto(:fallback)
:fallback
```
