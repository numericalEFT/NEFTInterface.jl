# NEFTInterface

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://numericaleft.github.io/NEFTInterface.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://numericaleft.github.io/NEFTInterface.jl/dev/)
[![Build Status](https://github.com/numericaleft/NEFTInterface.jl/actions/workflows/CI.yml/badge.svg?branch=master)](https://github.com/numericaleft/NEFTInterface.jl/actions/workflows/CI.yml?query=branch%3Amaster)
[![Coverage](https://codecov.io/gh/numericaleft/NEFTInterface.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/numericaleft/NEFTInterface.jl)

NEFTInterface.jl bridges Numerical Effective Field Theory pacakages with TRIQS and many other external packages.

## Features
 - Interface to the [`TRIQS`](https://triqs.github.io/) library.
 
## Installation
This package has been registered. So, simply type `import Pkg; Pkg.add("NEFTInterface")` in the Julia REPL to install.

## Interface with TRIQS
#  Interface with TRIQS

TRIQS (Toolbox for Research on Interacting Quantum Systems) is a scientific project providing a set of C++ and Python libraries for the study of interacting quantum systems. We provide a direct interface to convert TRIQS objects, such as the temporal meshes, the Brillouin zone meshes, and the  multi-dimensional (blocked) Green's functions, to the equivalent objects in our package. It would help TRIQS users to make use of our package without worrying about the different internal data structures.

We rely on the package [`PythonCall.jl`](https://github.com/cjdoris/PythonCall.jl) to interface with TRIQS' python API. You need to install TRIQS package from the python environment that `PythonCall` calls. We recommand you to check the sections [`Configuration`](https://cjdoris.github.io/PythonCall.jl/stable/pythoncall/#pythoncall-config) and [`Installing Python Package`](https://cjdoris.github.io/PythonCall.jl/stable/pythoncall/#python-deps) in the `PythonCall` documentation.

### Example 1: Load Triqs Temporal Mesh
First we show how to import an imaginary-time mesh from TRIQS.
```julia
    using PythonCall, NEFTInterface
    gf = pyimport("triqs.gf")
    np = pyimport("numpy")

    mt = gf.MeshImTime(beta=1.0, S="Fermion", n_max=3)
    mjt = from_triqs(mt)
    for (i, x) in enumerate([p for p in mt.values()])
        @assert mjt[i] ≈ pyconvert(Float64, x) # make sure mjt is what we want
    end
    
```
- With the `PythonCall` package, one can import python packages with `pyimport` and directly exert python code in Julia. Here we import the Green's function module `triqs.gf` and generate a uniform imaginary-time mesh with `MeshImTime`. The user has to specify the inverse temperature,  whether the particle is fermion or boson, and the number of grid points.

- Once a TRIQS object is prepared, one can simply convert it to an equivalent object in our package with `from_triqs`. The object can be a mesh, a Green's function, or a block Green's function. In this example, the TRIQS imaginary time grid is converted to an identical `ImTime` grid.

### Example 2: Load Triqs BrillouinZone

In this example, we show how the Brillouin zone mesh from TRIQS can be converted to a UniformMesh from the `BrillouinZoneMeshes.jl` package and clarify the convention we adopted to convert a Python data structure to its Julia counterpart.

```julia
    using PythonCall, NEFTInterface

    # construct triqs Brillouin zone mesh
    lat = pyimport("triqs.lattice")
    gf = pyimport("triqs.gf")
    BL = lat.BravaisLattice(units=((2, 0, 0), (1, sqrt(3), 0))) 
    BZ = lat.BrillouinZone(BL)
    nk = 4
    mk = gf.MeshBrillouinZone(BZ, nk)

    # load Triqs mesh and construct 
    mkj = from_triqs(mk)

    for p in mk
        pval = pyconvert(Array, p.value)
        # notice that TRIQS always return a 3D point, even for 2D case(where z is always 0)
        # notice also that Julia index starts from 1 while Python from 0
        # points of the same linear index has the same value
        ilin = pyconvert(Int, p.linear_index) + 1
        @assert pval[1:2] ≈ mkj[ilin]
        # points with the same linear index corresponds to REVERSED cartesian index
        inds = pyconvert(Array, p.index)[1:2] .+ 1
        @assert pval[1:2] ≈ mkj[reverse(inds)...]
    end
```

- Julia uses column-major layout for multi-dimensional array similar as Fortran and matlab, whereas python uses row-major layout. The converted Julias Brillouin zone mesh wll be indexed differently from that in TRIQS.
- We adopted the convention so that the grid point and linear index are consistent with TRIQS counterparts, while the orders of Cartesian index
and lattice vector are reversed.
- Here's a table of 2D converted mesh v.s. the Triqs counterpart:

| Object          | TRIQS             | Julia          |
| --------------- | ----------------- | -------------- |
| Linear index    | mk[i]=(x, y, 0)   | mkj[i]= (x, y) |
| Cartesian index | mk[i,j]=(x, y, 0) | mkj[j,i]=(x,y) |
| Lattice vector  | (a1, a2)          | (a2, a1)       |

### Example 3: Load Triqs Greens function of a Hubbard Lattice

A TRIQS Green's function is defined on a set of meshes of continuous variables, together with the discrete inner states specified by the `target_shape`. The structure casted into a `MeshArray` object provided by the package [`GreenFunc.jl`](https://github.com/numericalEFT/GreenFunc.jl). In the following example, we reimplement the example 3 in [`GreenFunc.jl` README](https://github.com/numericalEFT/GreenFunc.jl) to first show how to generate a TRIQS Green's function of a Hubbard lattice within Julia, then convert the TRIQS Green's function to a julia `MeshArray` object. The Green's function is given by $G(q, \omega_n) = \frac{1}{i\omega_n - \epsilon_q}$ with $\epsilon_q = -2t(\cos(q_x)+\cos(q_y))$. 

```julia
    using PythonCall, NEFTInterface, GreenFunc
    
    np = pyimport("numpy")
    lat = pyimport("triqs.lattice")
    gf = pyimport("triqs.gf")
    
    BL = lat.BravaisLattice(units=((2, 0, 0), (1, sqrt(3), 0))) # testing with a triangular lattice so that exchanged index makes a difference
    BZ = lat.BrillouinZone(BL)
    nk = 20
    mk = gf.MeshBrillouinZone(BZ, nk)
    miw = gf.MeshImFreq(beta=1.0, S="Fermion", n_max=100)
    mprod = gf.MeshProduct(mk, miw)

    G_w = gf.GfImFreq(mesh=miw, target_shape=[1, 1]) #G_w.data.shape will be [201, 1, 1]
    G_k_w = gf.GfImFreq(mesh=mprod, target_shape = [2, 3] ) #target_shape = [2, 3] --> innerstate = [3, 2]

    # Due to different cartesian index convention in Julia and Python, the data g_k_w[n, m, iw, ik] corresponds to G_k_w.data[ik-1, iw-1, m-1, n-1])

    t = 1.0
    for (ik, k) in enumerate(G_k_w.mesh[0])
        G_w << gf.inverse(gf.iOmega_n - 2 * t * (np.cos(k[0]) + np.cos(k[1])))
        G_k_w.data[ik-1, pyslice(0, nk^2), pyslice(0, G_k_w.target_shape[0]) , pyslice(0,G_k_w.target_shape[1])] = G_w.data[pyslice(0, nk^2), pyslice(0, G_w.target_shape[0]) , pyslice(0,G_w.target_shape[1])] #pyslice = :      
    end

    g_k_w = from_triqs(G_k_w)
    
    #alternatively, you can use the MeshArray constructor to convert TRIQS Green's function to a MeshArray
    g_k_w2 = MeshArray(G_k_w) 
    @assert g_k_w2 ≈ g_k_w

    #Use the << operator to import python data into an existing MeshArray 
    g_k_w2 << G_k_w
    @assert g_k_w2 ≈ g_k_w
    
```
- When converting a TRIQS Green's function into a `MeshArray` julia object, the `MeshProduct` from TRIQS is decomposed into separate meshes and converted to the corresponding Julia meshes. The `MeshArray` stores the meshes as a tuple object, not as a `MeshProduct`.
- The `target_shape` in TRIQS Green's function is converted to a tuple of `UnitRange{Int64}` objects that represents the discrete degrees of freedom. Data slicing with `:` is not available in `PythonCall`. One needs to use `pyslice` instead.
- As explained in Example 6, the cartesian index order of data has to be inversed during the conversion.
- We support three different interfaces for the conversion of TRIQS Green's function. One can construct a new MeshArray with `from_triqs` or `MeshArray` constructor. One can also load TRIQS Green's function into an existing `MeshArray` with the `<<` operator.

### Example 4: Load Triqs block Greens function

The block Greens function in TRIQS can be converted to a dictionary of `MeshArray` objects in julia. 

```julia
    using PythonCall, NEFTInterface, GreenFunc

    gf = pyimport("triqs.gf")
    np = pyimport("numpy")
    mt = gf.MeshImTime(beta=1.0, S="Fermion", n_max=3)
    lj = pyconvert(Int, @py len(mt))
    G_t = gf.GfImTime(mesh=mt, target_shape=[2,3]) #target_shape = [2, 3] --> innerstate = [3, 2]
    G_w = gf.GfImTime(mesh=mt, target_shape=[2,3]) #target_shape = [2, 3] --> innerstate = [3, 2]

    blockG = gf.BlockGf(name_list=["1", "2"], block_list=[G_t, G_w], make_copies=false)

    jblockG = from_triqs(blockG) 
    #The converted block Green's function is a dictionary of MeshArray corresponding to TRIQS block Green's function. The mapping between them is: jblockG["name"][i1, i2, t] = blockG["name"].data[t-1, i2-1, i1-1]

```