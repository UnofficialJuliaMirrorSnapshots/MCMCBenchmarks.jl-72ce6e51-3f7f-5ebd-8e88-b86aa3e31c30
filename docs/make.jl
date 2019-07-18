using Documenter, MCMCBenchmarks

makedocs(
    modules = [MCMCBenchmarks],
    checkdocs = :exports,
    authors = "Chris Fisher, Rob J Goedman",
    sitename = "StatisticalRethinkingJulia/MCMCBenchmarks.jl",
    pages = Any["index.md"]
)

deploydocs(
    repo = "github.com/StatisticalRethinkingJulia/MCMCBenchmarks.jl.git",
)
