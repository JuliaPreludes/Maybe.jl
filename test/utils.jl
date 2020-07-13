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
