Maybe.Extras.maybe(f::F) where {F} = MaybeFunction(f)

struct MaybeFunction{F} <: Function
    f::F
end
MaybeFunction(::Type{T}) where {T} = MaybeFunction{Type{T}}(T)
@inline (f::MaybeFunction)(args...; kwargs...) = maybecall(f.f, args...; kwargs...)

@inline function maybecall(f, args...; kwargs...)
    any(isnothing, args) && return nothing
    any(isnothing, Tuple(values(kwargs))) && return nothing
    return ensure_maybe(f(_somethings(args)...; _somethings(values(kwargs))...))
end

@inline _somethings(xs::Tuple) = map(something, xs)
@inline _somethings(xs::NamedTuple{names}) where {names} =
    NamedTuple{names}(_somethings(Tuple(xs)))

Maybe.Extras.ifnothing(f) = x -> Maybe.Extras.ifnothing(f, x)
Maybe.Extras.ifnothing(f, ::Nothing) = f()
Maybe.Extras.ifnothing(_, x::Some) = something(x)

Maybe.Extras.defaultto(c) = Maybe.Extras.ifnothing(() -> c)

@inline Maybe.Extras.getnested(x, k) = Maybe.get(x, k)
@inline Maybe.Extras.getnested(x, k, keys...) =
    Maybe.Extras.getnested(@something(Maybe.get(x, k), return), keys...)
@inline Maybe.Extras.getnested(x) = Some(x)

Maybe.Extras.definite(x) = x
Maybe.Extras.definite(x::Some) = Maybe.Extras.definite(something(x))

Maybe.Extras.asmissing(x) = something(Maybe.Extras.definite(x), missing)

Maybe.Extras.frommissing(::Missing) = nothing
Maybe.Extras.frommissing(x) = Some(x)
