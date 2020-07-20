module TestExtras

using Maybe.Extras
using Test

@testset "getnested" begin
    d = Dict(:a => Dict(:b => 1, :c => nothing))
    @test getnested(d, :a, :b) === Some(1)
    @test getnested(d, :a, :c) === Some(nothing)
    @test getnested(d, :a, :d) === nothing
end

@testset "ifnothing" begin
    @test nothing |> ifnothing() do
        0
    end == 0
    @test Some(1) |> ifnothing() do
        0
    end == 1
end

@testset "defaultto" begin
    @test nothing |> defaultto(0) == 0
    @test Some(1) |> defaultto(0) == 1
end

end  # module
