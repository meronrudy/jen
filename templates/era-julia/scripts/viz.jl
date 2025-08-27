#!/usr/bin/env julia
using JSON
import Base.Filesystem: mkpath

function main()
    mkpath("figures")
    if !isfile("runs/primary/metrics.json")
        @warn "Missing metrics; did you run train?"
        return 1
    end
    data = JSON.parsefile("runs/primary/metrics.json")
    open("figures/figure1.txt","w") do io
        write(io, "Figure1 placeholder: epochs=$(data["epochs"])\\n")
    end
    println("Wrote figures/figure1.txt")
    return 0
end

if abspath(PROGRAM_FILE) == @__FILE__
    exit(main())
end
