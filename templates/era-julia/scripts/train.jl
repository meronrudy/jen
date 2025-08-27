#!/usr/bin/env julia
using JSON, Dates

function main(config_path::String)
    mkpath("runs/primary")
    metrics = Dict(
        "epochs" => 1,
        "seed" => 42,
        "timestamp" => string(Dates.now(Dates.UTC))
    )
    open("runs/primary/metrics.json", "w") do io
        JSON.print(io, metrics)
    end
    println("Wrote runs/primary/metrics.json")
    return 0
end

if abspath(PROGRAM_FILE) == @__FILE__
    cfg = length(ARGS) >= 1 ? ARGS[1] : "params.toml"
    exit(main(cfg))
end
