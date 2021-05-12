module TestMaybe

using Test

# TODO: move this to Compat.jl
if try
    >=(1)
    false
catch
    true
end
    @info "Defining `>=(_)`"
    Base.:(>=)(b) = a -> a >= b
end

@testset "$file" for file in sort([
    file for file in readdir(@__DIR__) if match(r"^test_.*\.jl$", file) !== nothing
])
    if file == "test_doctest.jl"
        if lowercase(get(ENV, "JULIA_PKGEVAL", "false")) == "true"
            @info "Skipping doctests on PkgEval."
            continue
        elseif VERSION >= v"1.7-"
            @info "Skipping doctests on Julia $VERSION."
            continue
        end
    end

    include(file)
end

end  # module
