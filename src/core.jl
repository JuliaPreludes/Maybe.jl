const MaybeType{T} = Union{Some{T},Nothing}

Maybe.length(itr) =
    Base.IteratorSize(itr) isa Union{Base.HasShape,Base.HasLength} ? Some(length(itr)) :
    nothing
Maybe.eltype(itr) =
    Base.IteratorEltype(itr) isa Base.HasEltype ? Some(eltype(itr)) : nothing

@inline Maybe.first(xs) = Some(@something(iterate(xs), return)[1])
@inline Maybe.last(xs) = Maybe.get(xs, lastindex(xs))

@inline function Maybe.get(x::Union{AbstractDict,NamedTuple}, k)
    v = get(x, k, NoValue())
    v isa NoValue && return nothing
    return Some(v)
end

@inline Maybe.get(x::Tuple, k::Integer) = 1 <= k <= length(x) ? Some(x[k]) : nothing

@inline Maybe.get(x::AbstractArray, i) = Maybe.getindex(x, i)

@propagate_inbounds Maybe.getindex(xs, args...; kwargs...) =
    isempty(kwargs) ? posargs_getindex(xs, args...) : getindex(xs, args...; kwargs...)

@inline posargs_getindex(xs, args...) = getindex(xs, args...)
@inline posargs_getindex(xs::Tuple, key) = Maybe.get(xs, key)
posargs_getindex(xs::AbstractDict, key) = Maybe.get(xs, key)
posargs_getindex(xs::AbstractDict, k1, k2, keys...) = Maybe.get(xs, (k1, k2, keys...))

@propagate_inbounds posargs_getindex(xs::AbstractArray, i) = posargs_getindex_array(xs, i)
@propagate_inbounds posargs_getindex(xs::AbstractArray, indices...) =
    posargs_getindex_array(xs, indices...)

@propagate_inbounds function posargs_getindex_array(xs, indices...)
    @boundscheck checkbounds(Bool, xs, indices...) || return nothing
    return Some(@inbounds xs[indices...])
end

@inline Maybe.getproperty(x, name) =
    hasproperty(x, name) ? Some(getproperty(x, name)) : nothing
@inline Maybe.getproperty(x::Module, name::Symbol) =
    isdefined(x, name) ? Some(getfield(x, name)) : nothing
@inline Maybe.getproperty(x::NamedTuple, name::Symbol) = Maybe.get(x, name)
