Maybe.X.maybe(f::F) where {F} = MaybeFunction(f)

struct MaybeFunction{F} <: Function
    f::F
end
MaybeFunction(::Type{T}) where {T} = MaybeFunction{Type{T}}(T)
@inline (f::MaybeFunction)(args...; kwargs...) = maybecall(f.f, args...; kwargs...)

@inline function maybecall(f, args...; kwargs...)
    any(isnothing, args) && return nothing
    any(isnothing, Tuple(kwargs.data)) && return nothing
    return ensure_maybe(f(_somethings(args)...; _somethings(kwargs.data)...))
end

@inline _somethings(xs::Tuple) = map(something, xs)
@inline _somethings(xs::NamedTuple{names}) where {names} =
    NamedTuple{names}(_somethings(Tuple(xs)))

Maybe.X.ifnothing(f) = x -> Maybe.X.ifnothing(f, x)
Maybe.X.ifnothing(f, ::Nothing) = f()
Maybe.X.ifnothing(_, x::Some) = something(x)

Maybe.X.defaultto(c) = Maybe.X.ifnothing(() -> c)

@inline Maybe.X.getnested(x, k) = Maybe.get(x, k)
@inline Maybe.X.getnested(x, k, keys...) =
    Maybe.X.getnested(@something(Maybe.get(x, k), return), keys...)
@inline Maybe.X.getnested(x) = Some(x)
