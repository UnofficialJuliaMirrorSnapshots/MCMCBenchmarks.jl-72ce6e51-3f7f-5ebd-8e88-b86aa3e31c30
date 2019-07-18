using MCMCBenchmarks,Distributed
Nchains=4
setprocs(Nchains)

ProjDir = @__DIR__
cd(ProjDir)

isdir("tmp") && rm("tmp", recursive=true)
mkdir("tmp")
!isdir("results") && mkdir("results")
path = pathof(MCMCBenchmarks)
@everywhere begin
  using MCMCBenchmarks
  #Model and configuration patterns for each sampler are located in a
  #seperate model file.
  include(joinpath($path, "../../Models/LBA/LBA_Models.jl"))
  include(joinpath($path, "../../Models/LBA/LinearBallisticAccumulator.jl"))
end

#run this on primary processor to create tmp folder
include(joinpath(path, "../../Models/LBA/LBA_Models.jl"))
include(joinpath(path, "../../Models/LBA/LinearBallisticAccumulator.jl"))

@everywhere turnprogress(false)
#set seeds on each processor
seeds = (939388,39884,28484,495858,544443)
for (i,seed) in enumerate(seeds)
    @fetch @spawnat i Random.seed!(seed)
end

@everywhere Turing.turnprogress(false)

stanSampler = CmdStanNUTS(CmdStanConfig,ProjDir)
#Initialize model files for each instance of stan
initStan(stanSampler)

#create a sampler object or a tuple of sampler objects
samplers=(
  CmdStanNUTS(CmdStanConfig,ProjDir),
  AHMCNUTS(AHMClba,AHMCconfig),
  DHMCNUTS(sampleDHMC,2000))

#Number of data points
Nd = [10, 50, 200]

#Number of simulations
Nreps = 50

options = (Nsamples=2000,Nadapt=1000,delta=.8,Nd=Nd)
#perform the benchmark
results = pbenchmark(samplers,simulateLBA,Nreps;options...)

#save results
save(results,ProjDir)

pyplot()
cd(pwd)
dir = "results/"

#Plot parameter recovery
trueparms = Dict(Symbol("v[1]")=>1,Symbol("v[2]")=>1.5,Symbol("v[3]")=>2.5,:A=>.8,:k=>.2,:tau=>.4)
recoveryPlots = plotrecovery(results,trueparms,(:sampler,:Nd);save=true,dir=dir)

#Plot mean run time as a function of number of data points (Nd) for each sampler
meantimePlot = plotsummary(results,:Nd,:time,(:sampler,);save=true,dir=dir,yscale=:log10)

#Plot mean allocations as a function of number of data points (Nd) for each sampler
meanallocPlot = plotsummary(results,:Nd,:allocations,(:sampler,);save=true,dir=dir,yscale=:log10,
  ylabel="Allocations (log scale)")

#Plot mean ess per second of number of data points (Nd) for each sampler
meanallocPlot = plotsummary(results,:Nd,:ess_ps,(:sampler,);save=true,dir=dir)

#Plot density of effective sample size as function of number of data points (Nd) for each sampler
essPlots = plotdensity(results,:ess,(:sampler,:Nd);save=true,dir=dir)

#Plot density of rhat as function of number of data points (Nd) for each sampler
rhatPlots = plotdensity(results,:r_hat,(:sampler,:Nd);save=true,dir=dir)

#Plot density of time as function of number of data points (Nd) for each sampler
timePlots = plotdensity(results,:time,(:sampler,:Nd);save=true,dir=dir)

#Plot density of gc time percent as function of number of data points (Nd) for each sampler
gcPlots = plotdensity(results,:gcpercent,(:sampler,:Nd);save=true,dir=dir)

#Plot density of memory allocations as function of number of data points (Nd) for each sampler
memPlots = plotdensity(results,:allocations,(:sampler,:Nd);save=true,dir=dir,xscale=:log10,
  xlabel="Allocations (log scale)")

#Plot density of megabytes allocated as function of number of data points (Nd) for each sampler
megPlots = plotdensity(results,:megabytes,(:sampler,:Nd);save=true,dir=dir)

#Scatter plot of epsilon and effective sample size as function of number of data points (Nd) for each sampler
scatterPlots = plotscatter(results,:epsilon,:ess,(:sampler,:Nd);save=true,dir=dir)
