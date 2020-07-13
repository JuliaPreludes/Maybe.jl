module TestDoctest

using Documenter
using Test
using Maybe

@testset "/docs" begin
    doctest(Maybe; manual = true)
end

end  # module
