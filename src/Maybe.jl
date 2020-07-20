baremodule Maybe

export @something
# export @?

function length end
function eltype end
function get end
function getindex end
function getproperty end

# To avoid exporting `Extras` with `using Maybe.Extras`, using a
# different name:
baremodule _MaybeExtras_
export getnested, ifnothing, maybe, defaultto
function maybe end
function ifnothing end
function defaultto end
function getnested end
end

const Extras = _MaybeExtras_
const X = _MaybeExtras_

module Implementations
using ..Maybe: Maybe
using Base: @propagate_inbounds
using Base.Meta: isexpr
using ExprTools: combinedef, splitdef

if !@isdefined hasproperty
    using Compat: hasproperty
end

if !@isdefined isnothing
    using Compat: isnothing
end

if !isdefined(Base, Symbol("@var_str"))
    macro var_str(x)
        return Symbol(x)
    end
end

include("utils.jl")
include("something.jl")
include("core.jl")
include("lift.jl")
include("extras.jl")
finalize_implementations()
end

Implementations.finalize_package()

end