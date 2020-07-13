    Maybe.X.getnested(x, k₁, k₂, ..., kₙ) -> v::Union{Some{T},Nothing}

Try to get the item `v = x[k₁][k₂][...][kₙ]` and return `Some(v)`;
return `nothing` if the key does not exist.
