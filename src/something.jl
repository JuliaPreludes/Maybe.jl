macro something(args...)
    if length(args) == 1 && (exprs = statements_in_braces(args[1])) !== nothing
        return something_expr(__module__, __source__, exprs)
    elseif length(args) == 1 && isexpr(args[1], :bracescat)
        return something_expr(__module__, __source__, args[1].args)
    end
    return something_expr(__module__, __source__, args)
end

function something_expr(__module__, __source__, @nospecialize(args))
    foldr(
        collect(Any, args);
        init = :(throw(ArgumentError("all evaluated as `nothing`"))),
    ) do x, ex
        block = esc(Expr(:block, __source__, x))
        @gensym v
        quote
            local $v = $block
            if $v !== nothing
                something($v)
            else
                $ex
            end
        end
    end
end

"""
    statements_in_braces(ex)::Union{Vector{Any},Nothing}

This is used only for Julia >= 1.5.

# Examples
```julia
julia> using Maybe.Implementations: statements_in_braces

julia> statements_in_braces(:non_expression)

julia> statements_in_braces(:(@f {a; b; c}).args[end])
3-element Array{Any,1}:
 :a
 :b
 :c
```

# Notes
`@something{a; b; c}` and `@something{a; b; c;}` are parsed as

```lisp
(:macrocall, Symbol("@something"),
             :(#= ... =#),
             (:braces, (:parameters, (:parameters, :c), :b), :a))

(:macrocall, Symbol("@something"),
             :(#= ... =#),
             (:braces, (:parameters, (:parameters, (:parameters,), :c), :b), :a))
```

`parameters_as_statements` called from `statements_in_braces` converts
the `(:braces, ...)` part to `[:a, :b, :c]`.
"""
function statements_in_braces(ex)::Union{Vector{Any},Nothing}
    @nospecialize
    isexpr(ex, :braces) || return nothing
    isempty(ex.args) && return []
    if isexpr(ex.args[1], :parameters)
        return parameters_as_statements(Expr(:parameters, ex.args...))
    elseif length(ex.args) == 1
        return ex.args
    else
        return nothing
    end
end

function parameters_as_statements(ex)::Vector{Any}
    @nospecialize
    isexpr(ex, :parameters) || return Any[ex]
    if length(ex.args) == 0
        return []
    elseif length(ex.args) == 1
        return parameters_as_statements(ex.args[1])
    elseif length(ex.args) == 2 && isexpr(ex.args[1], :parameters)
        return append!(Any[ex.args[2]], parameters_as_statements(ex.args[1]))
    else
        error(
            "Semicolons and commas should not be mixed. ",
            "Use `{a; b; c}` instead of `{a; b, c}`.\n",
            "Error while parsing:\n",
            ex,
        )
    end
end
