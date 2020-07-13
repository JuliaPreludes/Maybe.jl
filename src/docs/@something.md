    @something(ex₁, ex₂, ..., exₙ)
    @something{ex₁; ex₂; ...; exₙ}
    @something {ex₁; ex₂; ...; exₙ}

A lazy version of `something(x₁, x₂, ..., xₙ)`.  Evaluate `exᵢ` one by
one and return `something(result)` of the first non-`nothing` `result`
of `exᵢ`.  Throw an error if everything is evaluated to `nothing`.

!!! note

    `@something{ex₁; ex₂; ...; exₙ}` requires Juila >= 1.5.

# Examples
```jldoctest
julia> using Maybe

julia> @something(
           (println("first"); nothing),
           (println("second"); 2),
           (println("third"); 3),
       )
first
second
2

julia> function maybe_add(xs)
           a = @something(get(xs, 1, nothing), return)
           b = @something(get(xs, 2, nothing), return)
           return a + b
       end;

julia> maybe_add([])

julia> maybe_add([3, 4])
7

julia> @something(nothing, nothing, nothing)
ERROR: ArgumentError: all evaluated as `nothing`
[...]
```

Since `@something` is often used with [`@?`](@ref), the form
`@something {ex₁; ex₂; ...; exₙ}` can also be used to avoid extra
parentheses:

```jldoctest; setup = :(using Maybe)
julia> d = Dict(:a => Dict(:b => 1, :c => nothing));

julia> @something {
           @? d[:A][:B];
           @? d[:A][:b];
           @? d[:a][:b];
           @? d[:c][:d];
       }
1

julia> @something(
           (@? d[:A][:B]),
           (@? d[:A][:b]),
           (@? d[:a][:b]),
           (@? d[:c][:d]),
       )
1
```
