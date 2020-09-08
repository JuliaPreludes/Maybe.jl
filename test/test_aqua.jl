module TestAqua

using Aqua
using Maybe
using Test

Aqua.test_all(
    Maybe;
    project_extras = true,
    stale_deps = (; ignore = [:Compat]),
    deps_compat = true,
    project_toml_formatting = true,
)

@testset "Compare test/Project.toml and test/environments/main/Project.toml" begin
    @test Text(read(joinpath(@__DIR__, "Project.toml"), String)) ==
          Text(read(joinpath(@__DIR__, "environments", "main", "Project.toml"), String))
end

end  # module
