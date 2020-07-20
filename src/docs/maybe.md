    maybe(f) -> f′

Transform ("lift") function `f(::T₁, ..., ::Tₙ) -> ::Union{Some{R}, R,
Nothing}` to `f′(::Union{Some{T₁}, Nothing}, ..., ::Union{Some{Tₙ},
Nothing}) -> ::Union{Some{R}, Nothing}`.

# Examples
```jldoctest
julia> using Maybe.Extras

julia> const ⊕ = maybe(+);

julia> 1 ⊕ nothing

julia> 1 ⊕ 2
Some(3)
```
