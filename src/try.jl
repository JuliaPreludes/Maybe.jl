Maybe.ok(result) = Try.isok(result) ? Some(Try.unwrap(result)) : nothing
Maybe.err(result) = Try.iserr(result) ? Some(Try.unwrap_err(result)) : nothing
