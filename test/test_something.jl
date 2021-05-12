module TestSomething

using Maybe
using Maybe: @something
using Maybe.Implementations: statements_in_braces
using Test

include("utils.jl")

@testset "statements_in_braces" begin
    stmts(ex::Expr) = statements_in_braces(ex.args[end])
    jl15"""
    @test stmts(:(@_{})) == Any[]
    @test stmts(:(@_{a})) == Any[:a]
    @test stmts(:(@_{a; b})) == Any[:a, :b]
    @test stmts(:(@_{a; b; c})) == Any[:a, :b, :c]
    @test stmts(:(@_{a; b; c;})) == Any[:a, :b, :c]
    @test_throws ErrorException stmts(:(@_{a; b, c;}))
    @test_throws ErrorException stmts(:(@_{a; b, c}))
    @test_throws ErrorException stmts(:(@_{a; b, c; d}))
    @test_throws ErrorException stmts(:(@_{a, b; c; d}))
    """
end

@testset "@something" begin
    hist = []
    rec(x) = push!(hist, x)
    @test @something(
        (rec(1); nothing),  # commas required
        (rec(2); nothing),
        (rec(3); :a),
        (rec(4); :b)
    ) === :a
    @test hist == [1, 2, 3]

    jl15"""
    hist = []
    @test @something{
        (rec(1); nothing);
        (rec(2); nothing);
        (rec(3); :a);
        (rec(4); :b);
    } === :a
    @test hist == [1, 2, 3]
    """

    hist = []
    @test (@something {
        (rec(1); nothing);
        (rec(2); nothing);
        (rec(3); :a);
        (rec(4); :b);
    }) === :a
    @test hist == [1, 2, 3]
end

@testset "with @?" begin
    d = Dict(:a => Dict(:b => 1, :c => nothing))
    @test (@something {
        @? d[:A][:B];
        @? d[:A][:b];
        @? d[:a][:b];
        @? d[:c][:d];
    }) === 1
    @test (@something {@? d[:a][:c]}) === nothing
    @test (@something (@? d[:a][:c])) === nothing
    jl15"""
    @test (@something {
        @? d[:A][:B];
        @? d[:A][:b];
        @? d[:a][:b];
        @? d[:c][:d];
    }) === 1
    @test (@something {@? d[:a][:c]}) === nothing
    @test (@something (@? d[:a][:c])) === nothing
    """
end

end  # module
