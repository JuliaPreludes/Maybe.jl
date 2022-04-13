    Maybe.Extras.ifnothing(f) -> x -> ifnothing(f, x)
    Maybe.Extras.ifnothing(f, nothing) -> f()
    Maybe.Extras.ifnothing(f, Some(x)) -> x

See also [`defaultto`](@ref Maybe.Extras.defaultto).

# Examples

```jldoctest
julia> using Maybe.Extras

julia> Some(1) |> ifnothing(() -> :fallback)
1

julia> nothing |> ifnothing(() -> :fallback)
:fallback
```
