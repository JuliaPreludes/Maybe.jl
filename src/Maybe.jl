baremodule Maybe

export @something
# export @?

function length end
function eltype end
function get end
function getindex end
function getproperty end

function _break end

baremodule Extras
export getnested, ifnothing, maybe, defaultto
function maybe end
function ifnothing end
function defaultto end
function getnested end
end

const X = Extras

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
