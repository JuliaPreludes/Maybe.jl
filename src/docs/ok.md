    Maybe.ok(Ok(x)) -> Some(x)
    Maybe.ok(Err(_)) -> nothing

Return a `Some` by re-wrapping a value inside an Ok result; return `nothing` on an Err
result.

See also [`Maybe.err`](@ref).

# Examples

```julia
julia> using Maybe, Try

julia> Maybe.ok(Ok(1))
Some(1)

julia> Maybe.ok(Err(1)) === nothing
true
```
