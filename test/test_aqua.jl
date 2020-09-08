module TestAqua

using Aqua
using Compat
using Maybe

Aqua.test_all(
    Maybe;
    project_extras = true,
    stale_deps = (; ignore = [Compat]),
    deps_compat = true,
    project_toml_formatting = true,
)

end  # module
