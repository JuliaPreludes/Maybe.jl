macro jl15_str(code::AbstractString)
    if VERSION >= v"1.5-rc0"
        @debug "Parsing code for Julia ≥ 1.5" Text(code)
        expr = Meta.parse(string("begin\n", code, "\nend"))
        @assert expr.head === :block
        if expr.args[1] isa LineNumberNode
            expr.args[1] = __source__
        end
        return esc(expr)
    else
        @debug "Skipping code in Julia < 1.5" Text(code)
        return nothing
    end
end

macro callmacro(ex)
    @assert Meta.isexpr(ex, :macrocall)
    return Expr(
        :call,
        ex.args[1],
        QuoteNode(ex.args[2]),
        __module__,
        map(QuoteNode, ex.args[3:end])...,
    )
end
