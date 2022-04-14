    Maybe.err(Err(x)) -> Some(x)
    Maybe.err(Ok(_)) -> nothing

Return a `Some` by re-wrapping a value inside an Err result; return `nothing` on an Ok
result.

See also [`Maybe.ok`](@ref).

# Examples

```julia
julia> using Maybe, Try

julia> Maybe.err(Ok(1)) === nothing
true

julia> Maybe.err(Err(1))
Some(1)
```
