@eval macro $(Symbol("?"))(ex)
    esc(maybe_macro(__module__, __source__, macroexpand(__module__, ex)))
end

@eval macro $(Symbol("?"))(debug, ex)
    if debug != QuoteNode(:debug)
        throw(ArgumentError(
            "two-argument form `@? :debug ex` only support" *
            " the flag `:debug`; got:\n$debug",
        ))
    end
    esc(maybe_macro(__module__, __source__, macroexpand(__module__, ex), true))
end

function isfunction(ex::Expr)
    (isexpr(ex, :function) || isexpr(ex, :->)) && return true
    if isexpr(ex, :(=), 2)
        a1 = ex.args[1]
        return isexpr(a1, :where) || isexpr(a1, :call)
    end
    return false
end

on_assignments(f, x) = x
on_assignments(f, ex::Expr) =
    if isexpr(ex, :block)
        Expr(:block, [on_assignments(f, x) for x in ex.args]...)
    elseif isexpr(ex, :(=), 2)
        Expr(:(=), f(ex.args[1], ex.args[2])...)
    else
        error("unsupported expression: $ex")
    end

first_line_number_node(_) = nothing
first_line_number_node(lnn::LineNumberNode) = lnn
function first_line_number_node(ex::Expr)
    for x in ex.args
        lnn = first_line_number_node(x)
        lnn == nothing || return lnn
    end
    return nothing
end

ensure_maybe(::Nothing) = nothing
ensure_maybe(x::Some) = x
ensure_maybe(x) = Some(x)

isdotop(_) = false
isdotop(x::Symbol) = Base.isoperator(x) && startswith(String(x), ".")

function Maybe._break()
    return nothing  # In debugger, use `up` to examine the state just before shortcircuit
end

function maybe_macro(__module__, __source__, expr0, debug::Bool = false)
    @gensym END
    lastline = Ref(__source__)
    callmacro(f, args...) = Expr(:macrocall, f, lastline[], args...)
    block(args...) = Expr(:block, lastline[], args...)
    lift(x) = x
    function lift(x::LineNumberNode)
        # Track the "best" line number to use.  This relies on that
        # the AST walking visits the node in the "line number order".
        # It could be a bit fragile but it looks like this is good
        # enough?
        lastline[] = x
        x
    end
    function lift(ex::Expr)
        if (
            isexpr(ex, :meta) ||
            isexpr(ex, :macrocall) ||
            isexpr(ex, :generator) ||
            isexpr(ex, :comprehension)
        )
            return ex
        elseif isfunction(ex)
            dict = splitdef(ex)
            dict[:body] = maybe_macro(__module__, lastline[], dict[:body])
            return combinedef(dict)
        elseif isexpr(ex, :call)
            f = ex.args[1]
            isdotop(f) && throw(ArgumentError("dot-call is not supported yet"))
            excall = liftcall(ex)
            if isexpr(f, :$, 1)
                if f.args[1] === :return && length(ex.args) == 2
                    # handling: $return(x)
                    return Expr(:return, lift(ex.args[2]))  # no `Some`
                else
                    # handling: $f(args...)
                    return ensure_maybe_expr(liftcall(ex))
                end
            else
                # handling: f(args...)
                return shortcircuit(liftcall(ex), ex)
            end
        elseif isexpr(ex, :tuple)
            return liftcall(ex)
        elseif isexpr(ex, :return, 1)
            ex.args[1] === nothing && return Expr(:return, nothing)  # 0-arg `return`
            return Expr(:return, Expr(:call, Some, lift(ex.args[1])))
        elseif isexpr(ex, :ref)
            return lift(Expr(:call, Maybe.getindex, ex.args...))
        elseif isexpr(ex, :., 2) && ex.args[2] isa QuoteNode
            return lift(Expr(:call, Maybe.getproperty, ex.args...))
        elseif isexpr(ex, :., 2) && isexpr(ex.args[2], :tuple)
            throw(ArgumentError("dot-call is not supported yet"))
        elseif isexpr(ex, :do, 2) && isexpr(ex.args[1], :call)
            excall = ex.args[1]
            if isexpr(get(excall.args, 1, nothing), :$, 1)
                excall = Expr(:call, excall.args[1].args[1], excall.args[2:end]...)
                return ensure_maybe_expr(Expr(:do, excall, lift(ex.args[2])))
            else
                return shortcircuit(Expr(:do, excall, lift(ex.args[2])), ex)
            end
        elseif isexpr(ex, :for, 2)
            destructs = []
            loopspec = on_assignments(ex.args[1]) do lhs, rhs
                local tmp = lhs isa Symbol ? gensym(lhs) : gensym("tmp")
                push!(destructs, :($lhs = $(shortcircuit(tmp))))
                return (tmp, liftconsume(rhs))
            end
            loopbody = Expr(
                :block,
                something(first_line_number_node(ex.args[2]), lastline[]),
                destructs...,
                ex.args[2],
            )
            return Expr(:for, loopspec, loopbody)
        elseif isexpr(ex, :(=)) && length(ex.args) > 0
            return Expr(:(=), ex.args[1:end-1]..., lift(ex.args[end]))
        elseif isexpr(ex, :$, 1)
            return ex.args[1]
        end
        return Expr(ex.head, map(lift, ex.args)...)
    end
    function shortcircuit(x, original = x)
        @gensym ans
        bailout = callmacro(var"@goto", END)
        if debug
            logargs = Any[:(evaluating = $(QuoteNode(original)))]
            if isdefined(Base, Symbol("@locals"))
                push!(logargs, :(locals = $(callmacro(getfield(Base, Symbol("@locals"))))))
            end
            bailout = Expr(
                :block,
                callmacro(
                    getfield(Base, Symbol("@debug")),
                    "Got `nothing`. Short-circuiting...",
                    logargs...,
                ),
                :($Maybe._break()),
                bailout,
            )
        end
        block(
            :(local $ans = $(block(x))),
            :($ans === nothing && $bailout),
            :($something($ans)),
        )
    end
    function liftconsume(x)
        if x === :nothing
            x
        elseif x isa Symbol
            shortcircuit(x)
        else
            lift(x)
        end
    end
    function ensure_maybe_expr(x)
        return :($ensure_maybe($x))
    end
    function liftcall(ex::Expr)
        @assert ex.head in (:call, :tuple, :parameters)
        if ex.head == :call
            args = append!(Any[lift(ex.args[1])], liftargs(ex.args[2:end]))
        else
            kwhead = ex.head === :tuple ? :(=) : :kw
            autokw = any(x -> isexpr(x, kwhead, 2), ex.args)
            args = liftargs(ex.args, kwhead, autokw)
        end
        return Expr(ex.head, args...)
    end
    function liftargs(args, kwhead = :kw, autokw = false)
        return map(args) do x
            if isexpr(x, kwhead, 2)
                Expr(kwhead, x.args[1], lift(x.args[2]))
            elseif autokw && x isa Symbol
                Expr(kwhead, x, lift(x))
            elseif isexpr(x, :call, 3) && x.args[1] == :(=>)
                f, a, b = x.args
                Expr(:call, f, lift(a), lift(b))
            elseif isexpr(x, :parameters)
                liftcall(x)
            elseif isexpr(x, :..., 1)
                Expr(:..., lift(x.args[1]))
            else
                liftconsume(x)
            end
        end
    end
    let result
        @gensym result
        quote
            local $result = nothing
            $result = $Some($(block(lift(expr0))))
            $(callmacro(var"@label", END))
            $result
        end
    end
end
