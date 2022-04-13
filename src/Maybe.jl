baremodule Maybe

export @something
# export @?

macro something end

function length end
function eltype end
function first end
function last end
function get end
function getindex end
function getproperty end

function ok end
function err end

function _break end

"""
    Maybe.Extras

A namespace for extra API; this is for preserving `Maybe.*` namespace
for (mainly) `Base`-compatible API.

Since there is no name clash with `Base` API, `using Maybe.Extras`
imports the API defined in `Maybe.Extras`.
"""
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
using ExternalDocstrings: @define_docstrings
using Try: Try

import ..Maybe: @something

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
include("lift.jl")
include("something.jl")
include("core.jl")
include("try.jl")
include("extras.jl")
finalize_implementations()
end

Implementations.finalize_package()
Implementations.@define_docstrings

end
