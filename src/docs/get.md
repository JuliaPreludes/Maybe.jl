    Maybe.get(d, k) -> Some(x) or nothing

Try to get an item `x` at key `k` and return `Some(x)` if found.
Return `nothing` if not found.

It is more efficient than calling `haskey(dict, key)` and then
`dict[key]` because it does not lookup the key twice.

# Examples

```jldoctest
julia> using Maybe

julia> Maybe.get(Dict(), :a)

julia> Maybe.get(Dict(:a => 1), :a)
Some(1)
```
