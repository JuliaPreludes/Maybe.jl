# # [How to use `@?`](@id tutorial)

using Maybe

using LiterateTest                                                     #src
using Test                                                             #src

# ## Introduction

# Julia `Base` provides functions `findfirst` and `findlast` that
# returns an integer when an element is found:

findfirst(x -> gcd(x, 42) == 21, 50:200)

# and `nothing` if not:

@assert findlast(x -> gcd(x, 42) == 23, 50:200) === nothing

# It is rather tedious to combine such functions:

function find_some_random_range_1(data)
    f(x) = gcd(x, 42) == 21
    i = findfirst(f, data)
    i === nothing && return nothing
    j = findlast(f, data)
    j === nothing && return nothing
    return data[i:j]
end

@assert find_some_random_range_1(50:200) === 63:189
@assert find_some_random_range_1(30:50) === nothing

# To solve this issue, Maybe.jl provides a macro [`@?`](@ref) that
# lets you write

function find_some_random_range_2(data)
    f(x) = gcd(x, 42) == 21
    @? begin
        i = findfirst(f, data)
        j = findlast(f, data)
        return data[i:j]
    end
end

@assert find_some_random_range_2(50:200) === Some(63:189)
@assert find_some_random_range_2(30:50) === nothing

# Similarly, `@?` is also useful for indexing into arrays,
# dictionaries, etc. that may fail.  For example

dict = Dict(:a => 1, :b => nothing, :c => 2)
@assert (@? dict[:a] + dict[:c]) == Some(3)
@assert (@? dict[:a] + dict[:non_existing_key]) === nothing

# This is explained in more details in [Indexing section](@ref
# tutorials-lift-macro-indexing) below.

# ## How it works

# The above example `find_some_random_range_2` is roughly equivalent
# to

function find_some_random_range_3(data)
    f(x) = gcd(x, 42) == 21
    mi = findfirst(f, data)
    mi === nothing && return nothing  # (1)
    i = something(mi)                 # (2)
    mj = findlast(f, data)
    mj === nothing && return nothing  # (1)
    j = something(mj)                 # (2)
    md = Maybe.getindex(data, i:j)    # (3)
    md === nothing && return nothing  # (1)
    d = something(md)                 # (2′)
    return Some(d)                    # (4)
end

@assert find_some_random_range_3(50:200) === Some(63:189)
@assert find_some_random_range_3(30:50) === nothing

# Observe that:
#
# (1) If a function returns `nothing`, the whole evaluation
# short-circuits and evaluates to `nothing`.  (Side notes:
# short-circuiting is not actually implemented using `return` in `@?`
# so that it can be used outside functions.)
#
# (2) The returned value is always unwrapped by `something`.  Thus, it
# works with "ordinary" functions like `+` as well as a function
# returning `Some` (like `Maybe.getindex`); see (2′).
#
# (3) Indexing dispatches to [`Maybe.getindex`](@ref).
#
# (4) Finally, the returned result is always ensured to be wrapped by
# `Some`.

# ## More examples

# Consider a function that returns `nothing` on "failure":

maybe_positive(x) = x > 0 ? x : nothing;

# When a function call in `@?` is evaluated to a non-`nothing`, the
# returned value is wrapped in `Some`:

@test begin
    @? maybe_positive(1)
end === Some(1)

# When `Some` appears in the argument positions, they are
# automatically un-wrapped:

@test begin
    @? maybe_positive(1) + 1
end === Some(2)

# `@?` is evaluated to `nothing` when the first sub-expression is
# evaluated to `nothing`:

@test begin
    global r = @? maybe_positive(-1) + 1
end === nothing
@assert r === nothing

# Literal `nothing` is transformed to `Some(nothing)`:

@test begin
    @? nothing
end === Some(nothing)

# `@?` terminates the call chain immediately when it sees `nothing` as
# the return value.

ARG_HISTORY = []
demo(label, x) = (push!(ARG_HISTORY, label => x); x)

@evaltest "r = @? demo(2, identity(demo(1, nothing)))" begin
    @test ans === nothing
    @test ARG_HISTORY == [1 => nothing]
end
@assert r === nothing

# Note that `demo(2, ...)` is not called:

ARG_HISTORY

# This can be avoided by prefixing the function name by `$`:

empty!(ARG_HISTORY)

@evaltest raw"@? $demo(2, $identity($demo(1, nothing)))" begin
    @test ans === Some(nothing)
    @test ARG_HISTORY == [1 => nothing, 2 => nothing]
end

# Now `demo(2, ...)` is called:

ARG_HISTORY

# This is because `@?` automatically unwraps `Some` in the call chain.
# It means that `Some` acts like the identity function inside `@?`:

@test begin
    @? Some(Some(Some(nothing)))
end === Some(nothing)

# On the other hand, `identity` acts like "unwrap" function:

@test begin
    global r = @? identity(identity(Some(nothing)))
end === nothing
@assert r === nothing

# Finally, with `$Some`:

@test begin
    @? $Some($Some($Some(nothing)))
end === Some(Some(Some(Some(nothing))))

# `$(expression)` can be used to evaluate the whole `expression` in
# the normal context

@test begin
    @? $(Some(Some(Some(nothing))))
end == Some(Some(Some(Some(nothing))))

# ## [Indexing](@id tutorials-lift-macro-indexing)

# Index access is also lifted.  Consider a dictionary

dict = Dict(:a => Dict(:b => nothing, :c => 2));

# Any value stored in the container (here, a `Dict`) is returned as a
# `Some`:

@test begin
    @? dict[:a][:c]
end === Some(2)

# Thus, `nothing` stored in the container is returned as
# `Some(nothing)`

@test begin
    @? dict[:a][:b]
end === Some(nothing)

# On the other hand, accessing non-existing index returns `nothing`:

@assert (@? dict[:a][:d]) === nothing
@assert (@? dict[:d]) === nothing

# Index access can be "fused" with other function calls:

@assert (@? dict[:a][:c] + 1) === Some(3)
@assert (@? dict[:a][:d] + 1) === nothing

# Existing `nothing` value can be normalized using `something` as
# usual inside `@?`.  This is because `@?` automatically unwraps
# `Some` once.

@assert (@? something(dict[:a][:b], 0) + 1) === Some(1)
@assert (@? something(dict[:a][:c], 0) + 1) === Some(3)
@assert (@? something(dict[:a][:d], 0) + 1) === nothing

# Since `identity` acts like unwrapping operation inside `@?`, it can
# be used for normalizing non-existing key and existing `nothing` to
# the same value:

@assert something((@? identity(dict[:a][:b])), 0) + 1 === 1
@assert something((@? identity(dict[:a][:c])), 0) + 1 === 3
@assert something((@? identity(dict[:a][:d])), 0) + 1 === 1

# Indexing also works with arrays

vectors = [[1, 2], [3, 4, 5]]

@assert (@? vectors[1][2]) === Some(2)
@assert (@? vectors[3][4]) === nothing
@assert (@? vectors[1][3]) === nothing

# ## `@? return`

# `return` in `@?` is a powerful pattern for returning a non-`nothing`
# value.

function first_something(dict)
    @? return dict[:a]
    @? return dict[:b]
    @? return dict[:c]
    return nothing
end

@assert first_something(Dict()) == nothing
@assert first_something(Dict(:c => 3)) == Some(3)
@assert first_something(Dict(:a => 1, :c => 3)) == Some(1)

# Alternatively, combined with [`@something`](@ref):

function first_something3(dict)
    return @something {
        @? dict[:a];
        @? dict[:b];
        @? dict[:c];
        0;  # fallback
    }
end

@assert first_something3(Dict()) === 0
@assert first_something3(Dict(:c => 3)) === 3
@assert first_something3(Dict(:a => 1, :c => 3)) === 1

# Note that `@?` can have multiple statements.  Any of the
# sub-expression evaluating to `nothing` short-circuits to the end of
# `@?` block.

function a_plus_b(dict)
    @? begin
        a = dict[:a]
        b = dict[:b]
        return a + b
    end
    return 0
end

@assert a_plus_b(Dict(:a => 1)) == 0
@assert a_plus_b(Dict(:a => 1, :b => 2)) == Some(3)

# Note that `@?` works with other control flows like `break`:

function something_positive_add3(xs, idx)
    found = nothing
    for i in idx
        @? if xs[i] > 0  # out-of-bound access is ignored
            found = i
            break
        end
    end
    return @? xs[found] + 3
end

@assert something_positive_add3([-1, 0, 1], [0, 1, 3]) === Some(4)
@assert something_positive_add3([-1, 0, 1], [0, 1, 2]) === nothing

# ## Combining `@?` and `@something`

# As explained, using `@?` in `@something` is well supported.
# However, further nesting is not supported (as the same expression
# would be processed by `@?` twice).  Assigning to an intermediate
# variable is a safe way to use the result of `@something` in `@?`.
# The pattern `@something(..., return)` is useful inside functions for
# this.

function extract_a_and_bc(x)
    c = @something {
        @? x[:b][:c];
        @? x[:b][:ccc];
        return;  # filter out if none of them exist
    }
    return @? (a = x[:a], c = c)
end

@assert extract_a_and_bc(Dict(:a => 1, :b => Dict(:c => 2))) === Some((a = 1, c = 2))
@assert extract_a_and_bc(Dict(:a => 1)) === nothing
@assert extract_a_and_bc(Dict(:a => 1, :b => Dict())) === nothing
@assert extract_a_and_bc(Dict(:b => Dict(:c => 2))) === nothing
@assert extract_a_and_bc(Dict(:a => 10, :b => Dict(:ccc => 20))) === Some((a = 10, c = 20))

# In a rare situation, it may be useful to use `$(...)` to nest
# `@something`-of-`@?`s in `@?`:

function a_plus_b_plus_c_or_d_times_2(x)
    @? begin
        p = x[:a] + x[:b]
        q = $(@something {
            @? p + x[:c];
            @? p + x[:d];
            Some(nothing);  # `return` works as well
        })
        return 2q
    end
end

@assert a_plus_b_plus_c_or_d_times_2(Dict(:a => 1, :b => 2, :c => 3)) == Some(12)
@assert a_plus_b_plus_c_or_d_times_2(Dict(:a => 1, :b => 2, :d => 3)) == Some(12)
@assert a_plus_b_plus_c_or_d_times_2(Dict(:a => 1, :b => 2)) === nothing

# ## Functions

# When `@?` sees functions (including closures and `do` blocks ), it
# converts them recursively to operate on `Union{Some{T},Nothing}`.

@? get_a_plus_b(dict) =
    get(dict, :a_plus_b) do
        dict[:a] + dict[:b]
    end

@assert get_a_plus_b(Dict(:a_plus_b => 1)) == Some(1)
@assert get_a_plus_b(Dict(:a => 1, :b => 2)) == Some(3)
@assert get_a_plus_b(Dict(:b => 1)) == nothing

# Thus, functions created with `@?` work nicely in `@?`:

@test begin
    @? begin
        x = get_a_plus_b(Dict(:a_plus_b => 1))
        y = get_a_plus_b(Dict(:a => 1, :b => 2))
        x + y
    end
end === Some(4)

@testset "get_a_plus_b" begin
    @test begin
        @? begin
            x = get_a_plus_b(Dict(:a_plus_b => 1))
            y = get_a_plus_b(Dict(:a => 1))
            x + y
        end
    end == nothing
    @test begin
        @? begin
            x = get_a_plus_b(Dict())
            y = get_a_plus_b(Dict(:a => 1, :b => 2))
            x + y
        end
    end == nothing
end
