module TestCore

using Test
using Maybe

@testset "get/getindex" begin
    @testset for get in [Maybe.get, Maybe.getindex]
        @test get(Dict(:a => 1), :a) === Some(1)
        @test get(Dict(:a => 1), :b) === nothing
        @test get((11, 22), 1) === Some(11)
        @test get((11, 22), 3) === nothing
        @test get((11, 22), 0) === nothing
    end
end

@noinline safe_getindex0(xs) = Maybe.getindex(xs, 0)
unsafe_getindex0(xs) = @inbounds Maybe.getindex(xs, 0)

@testset "getindex" begin
    @test Maybe.getindex(ones(2, 3), 1, 1) === Some(1.0)
    @test Maybe.getindex(ones(2, 3), 1, 0) === nothing
    @test safe_getindex0(1:2) === nothing
    if Base.JLOptions().check_bounds != 1
        @test unsafe_getindex0(1:2) === Some(0)
    end
end

module Sample
const someproperty = 1
end  # module Sample

@testset "getproperty" begin
    @test Maybe.getproperty(Sample, :someproperty) === Some(1)
    @test Maybe.getproperty(Sample, :length) === Some(length)
    @test Maybe.getproperty(Sample, :__init__) === nothing
end

@testset "length" begin
    @test Maybe.length(1:2) === Some(2)
    @test Maybe.length(x for x in 1:0 if false) === nothing
end

end  # module
