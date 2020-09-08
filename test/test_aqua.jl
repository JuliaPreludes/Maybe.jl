module TestAqua

using Aqua
using Maybe

Aqua.test_all(
    Maybe;
    project_extras = true,
    stale_deps = true,
    deps_compat = true,
    project_toml_formatting = true,
)

end  # module
