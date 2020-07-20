struct NoValue end

"""
    liftr(f) -> f′

Try to lift `X -> Y` to `X -> Union{Some{Y},Nothing}`; return `f`
as-is if not defined.
"""
liftr(f::F) where {F} = f

function define_liftr_impl()
    exprs = Expr[]
    for n in names(Maybe; all = true)
        @debug "`define_liftr_impl()`" n isdefined(Base, n)
        isdefined(Base, n) || continue
        f0 = getfield(Base, n)
        f1 = getfield(Maybe, n)
        @debug "`define_liftr_impl()`" f0 f1 f0 isa Function
        f0 isa Function || continue
        ex = quote
            liftr(::$(typeof(f0))) = $f1
        end
        push!(exprs, ex)
    end
    return Expr(:block, exprs...)
end

define_liftr() = Base.eval(Maybe.Implementations, define_liftr_impl())

function finalize_implementations()
    define_liftr()
end

# See ThreadsX.jl
function define_docstrings()
    docstrings = Pair[:Maybe=>joinpath(dirname(@__DIR__), "README.md")]
    docsdir = joinpath(@__DIR__, "docs")
    for filename in readdir(docsdir)
        stem, ext = splitext(filename)
        ext == ".md" || continue
        name = Symbol(stem)
        if name in names(Maybe, all = true)
            push!(docstrings, name => joinpath(docsdir, filename))
        elseif name in names(Maybe.Extras, all = true)
            push!(docstrings, :(Extras.$name) => joinpath(docsdir, filename))
        end
    end
    for (name, path) in docstrings
        include_dependency(path)
        doc = read(path, String)
        doc = replace(doc, r"^```julia"m => "```jldoctest $name")
        doc = replace(doc, "<kbd>TAB</kbd>" => "_TAB_")
        @eval Maybe $Base.@doc $doc $name
    end
end

function finalize_package()
    @eval Maybe begin
        const T = Implementations.MaybeType
        const $(Symbol("@something")) = Implementations.$(Symbol("@something"))
        const $(Symbol("@?")) = Implementations.$(Symbol("@?"))
        export $(Symbol("@?"))
    end
    define_docstrings()
end
