baremodule Maybe

export @something
# export @?

function length end
function eltype end
function get end
function getindex end
function getproperty end

baremodule X
export checktype, getnested, ifnothing, maybe, defaultto
function maybe end
function ifnothing end
function defaultto end
function getnested end
function checktype end
end

module Implementations
using ..Maybe: Maybe
using Base: @propagate_inbounds
using Base.Meta: isexpr
using ExprTools: combinedef, splitdef

if !@isdefined hasproperty
    using Compat: hasproperty
end

include("utils.jl")
include("something.jl")
include("core.jl")
include("lift.jl")
include("extras.jl")
Implementations.finalize_module()
end

end
