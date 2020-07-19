module TestLift

using Maybe
using Test

include("utils.jl")

@testset "identity" begin
    @test (@? nothing) === Some(nothing)
    @test (@? identity(nothing)) === nothing
    @test (@? Some(nothing)) === Some(nothing)
    @test (@? Some(Some(nothing))) === Some(nothing)
    @test (@? Some(Some(Some(nothing)))) === Some(nothing)
    @test (@? Some(Some(Some(nothing)))) === Some(nothing)
    @test (@? $Some($Some($Some(nothing)))) === Some(Some(Some(Some(nothing))))
end

@testset "return returns nothing" begin
    @? function f1()
        return
    end
    f2 = @? function ()
        return
    end
    f3 = @? () -> return
    @testset for f in map(something, [f1, f2, f3])
        @test f() === nothing
    end
end

@testset "return nothing returns something" begin
    @? function f1()
        return nothing
    end
    @? function f2()
    end
    f3 = @? function ()
        return nothing
    end
    f4 = @? function ()
    end
    @? f5() = nothing
    @? f6() = begin end
    f7 = @? () -> nothing
    f8 = @? () -> begin end
    @testset for f in map(something, [f1, f2, f3, f4, f5, f6, f7, f8])
        @test f() === Some(nothing)
    end
end
# Since `fᵢ` and `fᵢ₊₁` (`i` is odd) above should work identically,
# `return nothing` should be lifted to `return Some(nothing)`.

@testset "keyword arguments" begin
    f(a; b = 1, c = 2) = (a, b, c)
    f() = nothing
    @test (@? f(1; b = f())) === nothing
    @test (@? f(1, b = f())) === nothing
    @test (@? f(b = f(), 1)) === nothing
    @test (@? f(1; b = f(1; b = nothing)[2])) === Some((1, nothing, 2))
    @test (@? f(1, b = f(1, b = nothing)[2])) === Some((1, nothing, 2))
    @test (@? f(b = f(b = nothing, 1)[2], 1)) === Some((1, nothing, 2))
end

@testset "splatting (positional arguments)" begin
    t(args...) = args
    f() = nothing
    g() = (1, 2)
    h() = Some((1, 2))
    @test (@? t(0, f()...)) === nothing
    @test (@? t(0, g()...)) === Some((0, 1, 2))
    @test (@? t(0, h()...)) === Some((0, 1, 2))
    x = 0
    @test (@? t(x, f()...)) === nothing
    @test (@? t(x, g()...)) === Some((0, 1, 2))
    @test (@? t(x, h()...)) === Some((0, 1, 2))
    @test (@? t(f()..., x)) === nothing
    @test (@? t(g()..., x)) === Some((1, 2, 0))
    @test (@? t(h()..., x)) === Some((1, 2, 0))
    xname = :x
    @test (@? t(xname => x, f()...)) === nothing
    @test (@? t(xname => x, g()...)) === Some((xname => 0, 1, 2))
    @test (@? t(xname => x, h()...)) === Some((xname => 0, 1, 2))
end

@testset "splatting (keyword arguments)" begin
    t(; kwargs...) = kwargs.data
    f() = nothing
    g() = (a = 1, b = 2)
    h() = Some((a = 1, b = 2))
    @test (@? t(; x = 0, f()...)) === nothing
    @test (@? t(; x = 0, g()...)) === Some((x = 0, a = 1, b = 2))
    @test (@? t(; x = 0, h()...)) === Some((x = 0, a = 1, b = 2))
    x = 0
    @test (@? t(; x, y = 1, f()...)) === nothing
    @test (@? t(; x, y = 1, g()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    @test (@? t(; x, y = 1, h()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    xname = :x
    @test (@? t(; xname => x, y = 1, f()...)) === nothing
    @test (@? t(; xname => x, y = 1, g()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    @test (@? t(; xname => x, y = 1, h()...)) === Some((x = 0, y = 1, a = 1, b = 2))
end

@testset "splatting (mixed)" begin
    t(args...; kwargs...) = (args, kwargs.data)
    f() = nothing
    gt() = (1, 2)
    ht() = Some((1, 2))
    gk() = (a = 1, b = 2)
    hk() = Some((a = 1, b = 2))
    @test (@? t(x = 0, f()...)) === nothing
    @test (@? t(x = 0, gk()...)) === Some(t(x = 0, gk()...))
    @test (@? t(x = 0, hk()...)) === Some(t(x = 0, gk()...))
    @test (@? t(0, f()...; f()...)) === nothing
    @test (@? t(0, gt()...; gk()...)) === Some(t(0, gt()...; gk()...))
    @test (@? t(0, ht()...; hk()...)) === Some(t(0, gt()...; gk()...))
    x = 0
    @test (@? t(x, y = 1, f()...)) === nothing
    @test (@? t(x, y = 1, gk()...)) === Some(t(x, y = 1, gk()...))
    @test (@? t(x, y = 1, hk()...)) === Some(t(x, y = 1, gk()...))
    xname = :x
    @test (@? t(xname => x, y = 1, f()...)) === nothing
    @test (@? t(xname => x, y = 1, gk()...)) === Some(t(xname => x, y = 1, gk()...))
    @test (@? t(xname => x, y = 1, hk()...)) === Some(t(xname => x, y = 1, gk()...))
end

@testset "splatting (tuple)" begin
    f() = nothing
    g() = (1, 2)
    h() = Some((1, 2))
    @test (@? (0, f()...)) === nothing
    @test (@? (0, g()...)) === Some((0, 1, 2))
    @test (@? (0, h()...)) === Some((0, 1, 2))
    @test (@? tuple(0, f()...)) === nothing
    @test (@? tuple(0, g()...)) === Some((0, 1, 2))
    @test (@? tuple(0, h()...)) === Some((0, 1, 2))
    x = 0
    @test (@? (x, f()...)) === nothing
    @test (@? (x, g()...)) === Some((0, 1, 2))
    @test (@? (x, h()...)) === Some((0, 1, 2))
    @test (@? tuple(x, f()...)) === nothing
    @test (@? tuple(x, g()...)) === Some((0, 1, 2))
    @test (@? tuple(x, h()...)) === Some((0, 1, 2))
    xname = :x
    @test (@? (xname => x, f()...)) === nothing
    @test (@? (xname => x, g()...)) === Some((:x => 0, 1, 2))
    @test (@? (xname => x, h()...)) === Some((:x => 0, 1, 2))
    @test (@? tuple(xname => x, f()...)) === nothing
    @test (@? tuple(xname => x, g()...)) === Some((:x => 0, 1, 2))
    @test (@? tuple(xname => x, h()...)) === Some((:x => 0, 1, 2))
end

@testset "splatting (named tuple)" begin
    f() = nothing
    g() = (a = 1, b = 2)
    h() = Some((a = 1, b = 2))
    @test (@? (x = 0, f()...)) === nothing
    @test (@? (x = 0, g()...)) === Some((x = 0, a = 1, b = 2))
    @test (@? (x = 0, h()...)) === Some((x = 0, a = 1, b = 2))
    @test (@? (; x = 0, f()...)) === nothing
    @test (@? (; x = 0, g()...)) === Some((x = 0, a = 1, b = 2))
    @test (@? (; x = 0, h()...)) === Some((x = 0, a = 1, b = 2))
    x = 0
    @test (@? (x, y = 1, f()...)) === nothing
    @test (@? (x, y = 1, g()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    @test (@? (x, y = 1, h()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    @test (@? (; x, y = 1, f()...)) === nothing
    @test (@? (; x, y = 1, g()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    @test (@? (; x, y = 1, h()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    xname = :x
    @test (@? (xname => x, y = 1, f()...)) === nothing
    @test (@? (xname => x, y = 1, g()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    @test (@? (xname => x, y = 1, h()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    @test (@? (; xname => x, y = 1, f()...)) === nothing
    @test (@? (; xname => x, y = 1, g()...)) === Some((x = 0, y = 1, a = 1, b = 2))
    @test (@? (; xname => x, y = 1, h()...)) === Some((x = 0, y = 1, a = 1, b = 2))
end

struct Indexable end
Base.getindex(::Indexable, args...; kwargs...) = (args, kwargs.data)

@testset "Indexable" begin
    A = Indexable()
    ent = NamedTuple()
    @test A[1] === ((1,), ent)
    @test A[1, 2] === ((1, 2), ent)
    @test A[1, a = 2] === ((1,), (a = 2,))
end

@testset "getindex" begin
    A = Indexable()
    @test (@? A[1]) === Some(A[1])
    @test (@? A[1, 2]) === Some(A[1, 2])
    @test (@? A[1, a = 2]) === Some(A[1, a = 2])

    vov = [[11, 12], [21, 22, 23]]
    @test (@? vov[1][1]) === Some(vov[1][1])
    @test (@? vov[2][3]) === Some(vov[2][3])
    @test (@? vov[-1][1]) === nothing
    @test (@? vov[5][1]) === nothing
    @test (@? vov[1][-1]) === nothing
    @test (@? vov[1][5]) === nothing
end

@testset "getproperty" begin
    x = (a = (b = 1, c = nothing),)
    @test (@? x.a.b) === Some(1)
    @test (@? x.a.c) === Some(nothing)
    @test (@? x.a.c.d) === nothing
    @test (@? x.a.d) === nothing
    @test (@? x.d.e) === nothing
    nthg = nothing
    @test (@? nthg.a) === nothing
    n() = nothing
    @test (@? n().a) === nothing
end

@testset "destructuring bind" begin
    n() = nothing
    @test (@? begin
        a, b = n()
        a
    end) === nothing
    @test (@? begin
        a, b = (1, 2)
        a
    end) === Some(1)
end

@testset "control flows" begin
    t(_...) = true
    f(_...) = false
    n() = nothing
    @test (@? t() ? 1 : 2) === Some(1)
    @test (@? f() ? 1 : 2) === Some(2)
    @test (@? n() === nothing ? 1 : 2) === nothing
    @test (@? n() !== nothing ? 1 : 2) === nothing
    @test (@? $n() === nothing ? 1 : 2) === Some(1)
    @test (@? $n() !== nothing ? 1 : 2) === Some(2)
    @test (@? t() && t() ? 1 : 2) === Some(1)
    @test (@? t() && f() ? 1 : 2) === Some(2)
    @test (@? t() || t() ? 1 : 2) === Some(1)
    @test (@? t() || f() ? 1 : 2) === Some(1)
    @test (@? t() & t() ? 1 : 2) === Some(1)
    @test (@? t() & f() ? 1 : 2) === Some(2)
    @test (@? t() | t() ? 1 : 2) === Some(1)
    @test (@? t() | f() ? 1 : 2) === Some(1)
    @test (@? 1 < 2 < 3 ? 1 : 2) === Some(1)
    @test (@? 1 < 20 < 3 ? 1 : 2) === Some(2)
    @test (@? n() < 2 < 3 ? 1 : 2) === nothing
    @test (@? 1 < n() < 3 ? 1 : 2) === nothing
    @test (@? 1 < 2 < n() ? 1 : 2) === nothing
    @test (@? begin
        x = 2
        if t()
            x -= 1
        end
        x
    end) === Some(1)
    @test (@? begin
        x = 2
        if f()
            x -= 1
        end
        x
    end) === Some(2)
    @test (@? begin
        x = 2
        if t(n())
            x -= 1
        end
        x
    end) === nothing
    @test begin
        @? begin
            ys = []
            for x in 1:3
                push!(ys, x)
            end
            ys
        end
    end |> something |> ==(1:3)
    @test begin
        xs = [1, nothing, 2]
        @? begin
            ys = []
            for x in xs
                push!(ys, x)
            end
            ys
        end
    end === nothing
end

@testset "do" begin
    d = Dict(:a => 1)
    @test (@? get(d, :a) do; end) === Some(1)
    @test (@? get(d, :b) do; 2 end) === Some(2)
    @test (@? get(d, :b) do; return nothing end) === Some(nothing)
    @test (@? get(d, :b) do; end) === Some(nothing)
    @test (@? $get(d, :a) do; end) === Some(Some(1))
    @test (@? $get(d, :b) do; 2 end) === Some(Some(2))
    @test (@? $get(d, :b) do; return nothing end) === Some(Some(nothing))
    @test (@? $get(d, :b) do; end) === Some(Some(nothing))
end

@testset "unused" begin
    n() = nothing
    @test (@? begin
        n()
        1
    end) === nothing
end

@testset "literals" begin
    @test_broken (@? [1, nothing, 2]) |> something |> ==([1, Some(nothing), 2])
    @test_broken (@? [1; nothing; 2]) |> something |> ==([1; Some(nothing); 2])
    @test_broken (@? [1 2; nothing 4; 5 6]) |> something |> ==([1 2; Some(nothing) 4; 5 6])
    @test (@? [1, identity(nothing), 2]) === nothing
    @test (@? [1; identity(nothing); 2]) === nothing
    @test (@? [1 2; identity(nothing) 4; 5 6]) === nothing
end

@testset "type assertions" begin
    # Is this even possible with the current framework?
    d = Dict{Symbol,Any}(:a => Dict{Symbol,Any}(:b => 1))
    @test (@? begin
        a::Dict{Symbol,Any} = d[:a]
        b::Integer = a[:b]
        b + 1
    end) === Some(2)
end

@testset "dot-call" begin
    err = ArgumentError("dot-call is not supported yet")
    @test_throws err @callmacro @? a .+ b
    @test_throws err @callmacro @? f.(a, b)
    @test_throws err @callmacro @? g(f.(a, b))
    @test_throws err @callmacro @? f.(a, b) + c
    @test_throws err @callmacro @? f(a .+ b)
end

end  # module
