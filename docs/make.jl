using Documenter
using Maybe
using Literate
using LiterateTest

rm(joinpath(@__DIR__, "src", "tutorials"), force = true, recursive = true)
Literate.markdown(
    joinpath(@__DIR__, "..", "examples", "lift-macro.jl"),
    joinpath(@__DIR__, "src", "tutorials");
    config = LiterateTest.config(),
    documenter = true,
)

makedocs(
    sitename = "Maybe",
    format = Documenter.HTML(),
    modules = [Maybe],
    pages = [
        "index.md",
        "tutorials/lift-macro.md",
        # "How-to guides" => ...,
        # "Explanation" => ...,
    ],
)

# Hack: Replace `Maybe._MaybeExtras_` with `Maybe.Extras`
for (root, dirs, files) in walkdir(joinpath((@__DIR__), "build"))
    for name in files
        path = joinpath(root, name)
        txt = replace(read(path, String), "_MaybeExtras_" => "Extras")
        io = try
            open(path, write = true)
        catch
            continue
        end
        try
            write(io, txt)
        finally
            close(io)
        end
    end
end

deploydocs(; repo = "github.com/tkf/Maybe.jl", push_preview = true)
