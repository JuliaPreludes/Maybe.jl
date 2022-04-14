module TestTry

using Maybe
using Test
using Try

@testset begin
    @test Maybe.ok(Ok(1)) == Some(1)
    @test Maybe.ok(Err(1)) === nothing
    @test Maybe.err(Ok(1)) === nothing
    @test Maybe.err(Err(1)) == Some(1)
end

end  # module
