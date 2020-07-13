module TestExtras

using Maybe
using Test

@testset "getnested" begin
    d = Dict(:a => Dict(:b => 1, :c => nothing))
    @test Maybe.X.getnested(d, :a, :b) === Some(1)
    @test Maybe.X.getnested(d, :a, :c) === Some(nothing)
    @test Maybe.X.getnested(d, :a, :d) === nothing
end

end  # module
