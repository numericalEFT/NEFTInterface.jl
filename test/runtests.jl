using NEFTInterface
using GreenFunc
using Test

# @testset "NEFTInterface.jl" begin
#     # Write your tests here.
# end

if isempty(ARGS)
    include("test_Triqs.jl")
else
    include(ARGS[1])
end