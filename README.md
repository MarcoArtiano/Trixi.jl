# Trixi.jl

[![Docs-stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://trixi-framework.github.io/TrixiDocumentation/stable)
[![Docs-dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://trixi-framework.github.io/TrixiDocumentation/dev)
[![Slack](https://img.shields.io/badge/chat-slack-e01e5a)](https://join.slack.com/t/trixi-framework/shared_invite/zt-sgkc6ppw-6OXJqZAD5SPjBYqLd8MU~g)
[![Youtube](https://img.shields.io/youtube/channel/views/UCpd92vU2HjjTPup-AIN0pkg?style=social)](https://www.youtube.com/@trixi-framework)
[![Build Status](https://github.com/trixi-framework/Trixi.jl/actions/workflows/ci.yml/badge.svg)](https://github.com/trixi-framework/Trixi.jl/actions?query=workflow%3ACI)
[![Codecov](https://codecov.io/gh/trixi-framework/Trixi.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/trixi-framework/Trixi.jl)
[![Coveralls](https://coveralls.io/repos/github/trixi-framework/Trixi.jl/badge.svg?branch=main)](https://coveralls.io/github/trixi-framework/Trixi.jl?branch=main)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![License: MIT](https://img.shields.io/badge/License-MIT-success.svg)](https://opensource.org/licenses/MIT)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.3996439.svg)](https://doi.org/10.5281/zenodo.3996439)
[![OpenSSF Best Practices](https://www.bestpractices.dev/projects/8695/badge)](https://www.bestpractices.dev/projects/8695)
<!-- [![Downloads](https://shields.io/endpoint?url=https://pkgs.genieframework.com/api/v1/badge/Trixi)](https://pkgs.genieframework.com?packages=Trixi) -->
<!-- [![GitHub commits since tagged version](https://img.shields.io/github/commits-since/trixi-framework/Trixi.jl/v0.3.43.svg?style=social&logo=github)](https://github.com/trixi-framework/Trixi.jl) -->
<!-- [![PkgEval](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/T/Trixi.svg)](https://juliaci.github.io/NanosoldierReports/pkgeval_badges/report.html) -->

<p align="center">
  <img width="300px" src="https://trixi-framework.github.io/assets/logo.png">
</p>

**Trixi.jl** is a numerical simulation framework for conservation
laws written in [Julia](https://julialang.org). A key objective for the
framework is to be useful to both scientists and students. Therefore, next to
having an extensible design with a fast implementation, Trixi.jl is
focused on being easy to use for new or inexperienced users, including the
installation and postprocessing procedures. Its features include:

* 1D, 2D, and 3D simulations on [line/quad/hex/simplex meshes](https://trixi-framework.github.io/TrixiDocumentation/stable/overview/#Semidiscretizations)
  * Cartesian and curvilinear meshes
  * Conforming and non-conforming meshes
  * Structured and unstructured meshes
  * Hierarchical quadtree/octree grid with adaptive mesh refinement
  * Forests of quadtrees/octrees with [p4est](https://github.com/cburstedde/p4est) via [P4est.jl](https://github.com/trixi-framework/P4est.jl)
* High-order accuracy in space and time
  * Arbitrary floating-point precision
* Discontinuous Galerkin methods
  * Kinetic energy-preserving and entropy-stable methods based on flux differencing
  * Entropy-stable shock capturing
  * [Finite difference summation by parts (SBP) methods](https://github.com/ranocha/SummationByPartsOperators.jl)
* Advanced limiting strategies
  * Positivity-preserving limiting
  * Subcell invariant domain-preserving (IDP) limiting
  * Entropy-bounded limiting
* Compatible with the [SciML ecosystem for ordinary differential equations](https://diffeq.sciml.ai/latest/)
  * [Explicit low-storage Runge-Kutta time integration](https://diffeq.sciml.ai/latest/solvers/ode_solve/#Low-Storage-Methods)
  * [Strong stability preserving methods](https://diffeq.sciml.ai/latest/solvers/ode_solve/#Explicit-Strong-Stability-Preserving-Runge-Kutta-Methods-for-Hyperbolic-PDEs-(Conservation-Laws))
  * CFL-based and error-based time step control
* Custom explicit time integration schemes
  * Maximized linear stability via paired explicit Runge-Kutta methods
  * Relaxation Runge-Kutta methods for entropy-conservative time integration
* Native support for differentiable programming
  * Forward mode automatic differentiation via [ForwardDiff.jl](https://github.com/JuliaDiff/ForwardDiff.jl)
* Periodic and weakly-enforced boundary conditions
* Multiple governing equations:
  * Compressible Euler equations
  * Compressible Navier-Stokes equations
  * Magnetohydrodynamics (MHD) equations
  * Multi-component compressible Euler and MHD equations
  * Multi-ion compressible MHD equations
  * Linearized Euler and acoustic perturbation equations
  * Hyperbolic diffusion equations for elliptic problems
  * Lattice-Boltzmann equations (D2Q9 and D3Q27 schemes)
  * Shallow water equations via [TrixiShallowWater.jl](https://github.com/trixi-framework/TrixiShallowWater.jl)
  * Several scalar conservation laws (e.g., linear advection, Burgers' equation, LWR traffic flow)
* Multi-physics simulations
  * [Self-gravitating gas dynamics](https://github.com/trixi-framework/paper-self-gravitating-gas-dynamics)
* Shared-memory parallelization via multithreading
* Multi-node parallelization via MPI
* Visualization and postprocessing of the results
  * In-situ and a posteriori visualization with [Plots.jl](https://github.com/JuliaPlots/Plots.jl)
  * Interactive visualization with [Makie.jl](https://makie.juliaplots.org/)
  * Postprocessing with ParaView/VisIt via [Trixi2Vtk](https://github.com/trixi-framework/Trixi2Vtk.jl)


## Installation
If you have not yet installed Julia, please [follow the instructions for your
operating system](https://julialang.org/downloads/platform/). Trixi.jl works
with Julia v1.10 and newer. We recommend using the latest stable release of Julia.

### For users
Trixi.jl and its related tools are registered Julia packages. Hence, you
can install Trixi.jl, the visualization tools
[Trixi2Vtk](https://github.com/trixi-framework/Trixi2Vtk.jl), and
[Plots.jl](https://github.com/JuliaPlots/Plots.jl)
as well as the time integration sub-packages of
[OrdinaryDiffEq.jl](https://github.com/SciML/OrdinaryDiffEq.jl),
by executing the following commands in the Julia REPL:
```julia
julia> using Pkg

julia> Pkg.add(["Trixi", "Trixi2Vtk", "OrdinaryDiffEqLowStorageRK",
                "OrdinaryDiffEqSSPRK", "Plots"])
```
You can copy and paste all commands to the REPL *including* the leading
`julia>` prompts - they will automatically be stripped away by Julia.
The package [OrdinaryDiffEq.jl](https://github.com/SciML/OrdinaryDiffEq.jl)
and its sub-packages provide time integration schemes used by Trixi.jl, while
[Plots.jl](https://github.com/JuliaPlots/Plots.jl) can be used to directly
visualize Trixi.jl's results from the REPL.

*Note on package versions:* If some of the examples for how to use Trixi.jl do not
work, verify that you are using a recent Trixi.jl release by comparing the
installed Trixi.jl version from
```julia
julia> using Pkg; Pkg.update("Trixi"); Pkg.status("Trixi")
```
to the [latest release](https://github.com/trixi-framework/Trixi.jl/releases/latest).
If the installed version does not match the current release, please check the
*Troubleshooting* section in the [documentation](#documentation).

The commands above can also be used to update Trixi.jl. A brief list of notable
changes to Trixi.jl is available in [`NEWS.md`](NEWS.md).

### For developers
If you plan on editing Trixi.jl itself, you can download Trixi.jl locally and use the
code from the cloned directory:
```bash
git clone git@github.com:trixi-framework/Trixi.jl.git
cd Trixi.jl
mkdir run
cd run
julia --project=. -e 'using Pkg; Pkg.develop(PackageSpec(path=".."))' # Install local Trixi.jl clone
julia --project=. -e 'using Pkg; Pkg.add(["OrdinaryDiffEq", "Trixi2Vtk", "Plots"])' # Install additional packages
```
Note that the postprocessing tools Trixi2Vtk.jl and Plots.jl are optional and
can be omitted.

If you installed Trixi.jl this way, you always have to start Julia with the `--project`
flag set to your `run` directory, e.g.,
```bash
julia --project=.
```
if already inside the `run` directory.
Further details can be found in the [documentation](#documentation).


## Usage
In the Julia REPL, first load the package Trixi.jl
```julia
julia> using Trixi
```
Then start a simulation by executing
```julia
julia> trixi_include(default_example())
```
Please be patient since Julia will compile the code just before running it.
To visualize the results, load the package Plots
```julia
julia> using Plots
```
and generate a heatmap plot of the results with
```julia
julia> plot(sol) # No trailing semicolon, otherwise no plot is shown
```
This will open a new window with a 2D visualization of the final solution:
<p align="center">
  <img width="300px" src="https://user-images.githubusercontent.com/26361975/177492363-74cee347-7abe-4522-8b2d-0dfadc317f7e.png">
</p>

The method `trixi_include(...)` expects a single string argument with the path to a
Trixi.jl elixir, i.e., a text file containing Julia code necessary to set up and run a
simulation. To quickly see Trixi.jl in action, `default_example()`
returns the path to an example elixir with a short, two-dimensional
problem setup. A list of all example elixirs packaged with Trixi.jl can be
obtained by running `get_examples()`. Alternatively, you can also browse the
[`examples/`](examples/) subdirectory.
If you want to modify one of the elixirs to set up your own simulation,
download it to your machine, edit the configuration, and pass the file path to
`trixi_include(...)`.

*Note on performance:* Julia uses just-in-time compilation to transform its
source code to native, optimized machine code at the *time of execution* and
caches the compiled methods for further use. That means that the first execution
of a Julia method is typically slow, with subsequent runs being much faster. For
instance, in the example above the first execution of `trixi_include` takes about
20 seconds, while subsequent runs require less than 60 *milli*seconds.

### Showcase of advanced features
The presentation [From Mesh Generation to Adaptive Simulation: A Journey in Julia](https://youtu.be/_N4ozHr-t9E),
originally given as part of JuliaCon 2022, outlines how to use Trixi.jl for an adaptive simulation
of the compressible Euler equations in two spatial dimensions on a complex domain. More details
as well as code to run the simulation presented can be found at the
[reproducibility repository](https://github.com/trixi-framework/talk-2022-juliacon_toolchain)
for the presentation.

## Documentation
Additional documentation is available that contains more information on how to
modify/extend Trixi.jl's implementation, how to visualize output files etc. It
also includes a section on our preferred development workflow and some tips for
using Git. The latest documentation can be accessed either
[online](https://trixi-framework.github.io/TrixiDocumentation/stable) or under [`docs/src`](docs/src).


## Referencing
If you use Trixi.jl in your own research or write a paper using results obtained
with the help of Trixi.jl, please cite the following articles:
```bibtex
@article{ranocha2022adaptive,
  title={Adaptive numerical simulations with {T}rixi.jl:
         {A} case study of {J}ulia for scientific computing},
  author={Ranocha, Hendrik and Schlottke-Lakemper, Michael and Winters, Andrew Ross
          and Faulhaber, Erik and Chan, Jesse and Gassner, Gregor},
  journal={Proceedings of the JuliaCon Conferences},
  volume={1},
  number={1},
  pages={77},
  year={2022},
  doi={10.21105/jcon.00077},
  eprint={2108.06476},
  eprinttype={arXiv},
  eprintclass={cs.MS}
}

@article{schlottkelakemper2021purely,
  title={A purely hyperbolic discontinuous {G}alerkin approach for
         self-gravitating gas dynamics},
  author={Schlottke-Lakemper, Michael and Winters, Andrew R and
          Ranocha, Hendrik and Gassner, Gregor J},
  journal={Journal of Computational Physics},
  pages={110467},
  year={2021},
  month={06},
  volume={442},
  publisher={Elsevier},
  doi={10.1016/j.jcp.2021.110467},
  eprint={2008.10593},
  eprinttype={arXiv},
  eprintclass={math.NA}
}
```

In addition, you can also refer to Trixi.jl directly as
```bibtex
@misc{schlottkelakemper2025trixi,
  title={{T}rixi.jl: {A}daptive high-order numerical simulations
         of hyperbolic {PDE}s in {J}ulia},
  author={Schlottke-Lakemper, Michael and Gassner, Gregor J and
          Ranocha, Hendrik and Winters, Andrew R and Chan, Jesse
          and Rueda-Ramírez, Andrés},
  year={2025},
  howpublished={\url{https://github.com/trixi-framework/Trixi.jl}},
  doi={10.5281/zenodo.3996439}
}
```


## Authors
Trixi.jl was initiated by [Michael
Schlottke-Lakemper](https://www.uni-augsburg.de/fakultaet/mntf/math/prof/hpsc)
(University of Augsburg, Germany) and
[Gregor Gassner](https://www.mi.uni-koeln.de/NumSim/gregor-gassner)
(University of Cologne, Germany). Together with [Hendrik Ranocha](https://ranocha.de)
(Johannes Gutenberg University Mainz, Germany), [Andrew Winters](https://liu.se/en/employee/andwi94)
(Linköping University, Sweden), [Jesse Chan](https://jlchan.github.io) (Rice University, US),
and [Andrés Rueda-Ramírez](https://andres.rueda-ramirez.com) (Polytechnic University of Madrid (UPM), Spain),
they are the principal developers of Trixi.jl.
The full list of contributors can be found in [AUTHORS.md](AUTHORS.md).


## License and contributing
Trixi.jl is licensed under the MIT license (see [LICENSE.md](LICENSE.md)). Since Trixi.jl is
an open-source project, we are very happy to accept contributions from the
community. Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for more details.
Note that we strive to be a friendly, inclusive open-source community and ask all members
of our community to adhere to our [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).
To get in touch with the developers,
[join us on Slack](https://join.slack.com/t/trixi-framework/shared_invite/zt-sgkc6ppw-6OXJqZAD5SPjBYqLd8MU~g)
or [create an issue](https://github.com/trixi-framework/Trixi.jl/issues/new).

## Participating research groups
Participating research groups in alphabetical order:

[Applied and Computational Mathematics, RWTH Aachen University :de:](https://www.acom.rwth-aachen.de)

[Applied Mathematics, Department of Mathematics, University of Hamburg :de:](https://www.math.uni-hamburg.de/en/forschung/bereiche/am.html)

[Department of Applied Mathematics in Aerospace Engineering, Polytechnic University of Madrid (UPM) :es:](https://numath.dmae.upm.es/)

[Division of Applied Mathematics, Department of Mathematics, Linköping University :sweden:](https://liu.se/en/employee/andwi94)

[Computational and Applied Mathematics, Rice University :us:](https://jlchan.github.io/)

[High-Performance Computing, Institute of Software Technology, German Aerospace Center (DLR) :de:](https://www.dlr.de/en/sc/about-us/departments/high-performance-computing)

[High-Performance Scientific Computing, University of Augsburg :de:](https://hpsc.math.uni-augsburg.de)

[Numerical Mathematics, Institute of Mathematics, Johannes Gutenberg University Mainz :de:](https://ranocha.de)

[Numerical Simulation, Department of Mathematics and Computer Science, University of Cologne :de:](https://www.mi.uni-koeln.de/NumSim/)


## Acknowledgments
<p align="center" style="font-size:0;"><!--
  BMBF     --><img align="middle" src="https://github.com/trixi-framework/Trixi.jl/assets/3637659/f59af636-3098-4be6-bf80-c6be3f17cbc6" height="120"><!--
  DFG      --><img align="middle" src="https://github.com/trixi-framework/Trixi.jl/assets/3637659/e67b9ed3-7699-466a-bdaf-2ba070a29a8e" height="120"><!--
  SRC      --><img align="middle" src="https://github.com/trixi-framework/Trixi.jl/assets/3637659/48f9da06-6f7a-4586-b23e-739bee3901c0" height="120"><!--
  ERC      --><img align="middle" src="https://github.com/trixi-framework/Trixi.jl/assets/3637659/9371e7e4-3491-4433-ac5f-b3bfb215f5ca" height="120"><!--
  NSF      --><img align="middle" src="https://github.com/trixi-framework/Trixi.jl/assets/3637659/5325103c-ae81-4747-b87c-c6e4a1b1d7a8" height="120"><!--
  DUBS     --><img align="middle" src="https://github.com/trixi-framework/Trixi.jl/assets/3637659/bb021e6e-42e6-4fe1-a414-c847402e1937" height="120"><!--
  NumFOCUS --><img align="middle" src="https://github.com/trixi-framework/Trixi.jl/assets/3637659/8496ac9e-b586-475f-adb7-69bcfc415185" height="120"><!--
  -->
</p>

This project has benefited from funding by the [Deutsche
Forschungsgemeinschaft](https://www.dfg.de/) (DFG, German Research Foundation)
through the following grants:
* Excellence Strategy EXC 2044-390685587, Mathematics Münster: Dynamics-Geometry-Structure.
* Research unit FOR 5409 "Structure-Preserving Numerical Methods for Bulk- and
  Interface Coupling of Heterogeneous Models ([SNuBIC](https://www.snubic.io))" (project number 463312734).
* Individual grant no. 528753982.

This project has benefited from funding from the [European Research Council](https://erc.europa.eu)
through the
ERC Starting Grant "An Exascale aware and Un-crashable Space-Time-Adaptive
Discontinuous Spectral Element Solver for Non-Linear Conservation Laws" (Extreme),
ERC grant agreement no. 714487.

This project has benefited from funding from [Vetenskapsrådet](https://www.vr.se)
(VR, Swedish Research Council), Sweden
through the VR Starting Grant "Shallow water flows including sediment transport and morphodynamics",
VR grant agreement 2020-03642 VR.

This project has benefited from funding from the United States
[National Science Foundation](https://www.nsf.gov/) (NSF) under awards
DMS-1719818 and DMS-1943186.

This project has benefited from funding from the German
[Federal Ministry of Education and Research](https://www.bmbf.de) (BMBF)
through the following grants:
* Project grant "Adaptive earth system modeling with significantly reduced computation time for
  exascale supercomputers (ADAPTEX)" (funding id: 16ME0668K)
* Project grant "ICON-DG" of the WarmWorld initiative (funding id: 01LK2315B).

This project has benefited from funding by the
[Daimler und Benz Stiftung](https://www.daimler-benz-stiftung.de) (Daimler and Benz Foundation)
through grant no. 32-10/22.

This project has benefited from funding by the
[Klaus Tschira Stiftung](https://klaus-tschira-stiftung.de/) (Klaus Tschira Foundation)
through the project grant "High-Fidelity Laboratory for the Simulation of Celestial Bodies with their Space Environment (HiFiLab)" (funding id: 00.014.2021).

This project has benefited from funding by the Spanish
[Ministry of Science, Innovation, and Universities](https://www.ciencia.gob.es/en/)
through the "Beatriz Galindo" grant no. BG23-00062.

Trixi.jl is supported by [NumFOCUS](https://numfocus.org/) as an Affiliated Project.
