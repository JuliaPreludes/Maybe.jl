    Maybe.getproperty(object, name) -> Some(property) or nothing

Return the property named `name` if `object` has it.

# Examples

```jldoctest
julia> using Maybe

julia> Maybe.getproperty((a = 1,), :b)

julia> Maybe.getproperty((a = 1,), :a)
Some(1)
```
