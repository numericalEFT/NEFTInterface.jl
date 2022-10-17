using NEFTInterface
using Documenter

DocMeta.setdocmeta!(NEFTInterface, :DocTestSetup, :(using NEFTInterface); recursive=true)

makedocs(;
    modules=[NEFTInterface],
    authors="Kun Chen, Tao Wang, Xiansheng Cai, PengCheng Hou, and Zhiyi Li",
    repo="https://github.com/numericalEFT/NEFTInterface.jl/blob/{commit}{path}#{line}",
    sitename="NEFTInterface.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://numericaleft.github.io/NEFTInterface.jl",
        edit_link="master",
        assets=String[]
    ),
    pages=[
        "Home" => "index.md",
        "Reference" => "lib/triqs.md",
    ]
)

deploydocs(;
    repo="github.com/numericalEFT/NEFTInterface.jl",
    devbranch="master"
)
