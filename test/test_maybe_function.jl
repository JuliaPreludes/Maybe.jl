module TestMaybeFunction

using Maybe.Extras
using Test

retargs(args...; kwargs...) = (args, values(kwargs))

@testset begin
    @test maybe(retargs)(nothing) === nothing
    @test maybe(retargs)(1, nothing, 2) === nothing
    @test maybe(retargs)(1, nothing, 2; a = 3) === nothing
    @test maybe(retargs)(Some(nothing)) === Some(retargs(nothing))
    @test maybe(retargs)(Some(nothing); a = 1) === Some(retargs(nothing, a = 1))
    @test maybe(retargs)(Some(nothing); a = Some(nothing)) ===
          Some(retargs(nothing, a = nothing))
end

end  # module
