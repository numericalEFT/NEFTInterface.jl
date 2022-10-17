using NEFTInterface
using Documenter

DocMeta.setdocmeta!(NEFTInterface, :DocTestSetup, :(using NEFTInterface); recursive=true)

makedocs(;
    modules=[NEFTInterface],
    authors="Kun Chen",
    repo="https://github.com/numericaleft/NEFTInterface.jl/blob/{commit}{path}#{line}",
    sitename="NEFTInterface.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://numericaleft.github.io/NEFTInterface.jl",
        edit_link="main",
        assets=String[]
    ),
    pages=[
        "Home" => "index.md",
    ]
)

deploydocs(;
    repo="github.com/numericaleft/NEFTInterface.jl",
    devbranch="master"
)
