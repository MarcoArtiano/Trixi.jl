# Changelog

Trixi.jl follows the interpretation of
[semantic versioning (semver)](https://julialang.github.io/Pkg.jl/dev/compatibility/#Version-specifier-format-1)
used in the Julia ecosystem. Notable changes will be documented in this file
for human readability.


## Changes when updating to v0.13 from v0.12.x

#### Changed

- The `polyester` preference got merged with the `native_threading` preference and the `Trixi.set_polyester!` 
  function got renamed to `Trixi.set_threading_backend!` ([#2476]).
- Default wave-speed estimate used within `flux_lax_friedrichs` changed from `max_abs_speed_naive` to
  `max_abs_speed` which is less diffusive.
  In v0.13, `flux_lax_friedrichs = FluxLaxFriedrichs(max_abs_speed = max_abs_speed)`
  instead of the previous default 
  `FluxLaxFriedrichs(max_abs_speed = max_abs_speed_naive)` ([#2458]).
- The signature of the `VisualizationCallback` constructor changed.
  In the new version, it is mandatory to pass the semidiscretization `semi` to
  determine the default plotting type (1D for 1D simulations, 2D for 2D and 3D simulations).
  This can further be customized via the keyword argument `plot_data_creator`, which had
  the default value `plot_data_creator = PlotData2D` before the change ([#2468]).

#### Removed

- Deprecations introduced in earlier versions of Trixi.jl have been removed.


## Changes in the v0.12 lifecycle

#### Added
- Initial support for adapting data-structures between different storage arrays was added. This enables future work to support GPU with Trixi ([#2212]).

#### Deprecated


## Changes when updating to v0.12 from v0.11.x

#### Added

- Arbitrary solution-dependent quantities can now be saved in the `SaveSolutionCallback` (and thus later on visualized) ([#2298]).
- Added support for nonconservative terms with "local * jump" formulation in `VolumeIntegralSubcellLimiting` ([#2429]).

#### Changed

- When using the `VolumeIntegralSubcellLimiting` with the `SubcellLimiterIDP` the
  `:limiting_coefficient` must be explicitly provided to the `SaveSolutionCallback` via
  ```julia
  save_sol_cb = SaveSolutionCallback(interval = 42,
                                     extra_node_variables = (:limiting_coefficient,))
  ```
  i.e., is no longer automatically saved ([#2298]).

#### Deprecated

#### Removed

- The shallow-water equation types `ShallowWaterEquations1D`, `ShallowWaterEquations2D`, and
  `ShallowWaterEquationsQuasi1D` have been removed from Trixi.jl and are now available via
  [TrixiShallowWater.jl](https://github.com/trixi-framework/TrixiShallowWater.jl/).
  This also affects the related functions `hydrostatic_reconstruction_audusse_etal`,
  `flux_nonconservative_audusse_etal`, and `FluxHydrostaticReconstruction`. ([#2379])
- The additional `ìnitial_cache` entries in the caches of `SemidiscretizationHyperbolic`
  and `SemidiscretizationHyperbolicParabolic`, and the corresponding keyword arguments of
  their constructors have been removed. ([#2399])

## Changes in the v0.11 lifecycle

#### Added

- Added symmetry plane/reflective wall velocity+stress boundary conditions for the compressible Navier-Stokes equations in 2D and 3D.
  Currently available only for the `P4estMesh` mesh type, `GradientVariablesPrimitive`, and `Adiabatic` heat boundary condition ([#2416]).
- Added `LaplaceDiffusionEntropyVariables1D`, `LaplaceDiffusionEntropyVariables2D`, and `LaplaceDiffusionEntropyVariables3D`. These add scalar diffusion to each
  equation of a system, but apply diffusion in terms of the entropy variables, which symmetrizes the viscous formulation and ensures semi-discrete entropy dissipation ([#2406]).
- Added the three-dimensional multi-ion magneto-hydrodynamics (MHD) equations with a
  generalized Lagrange multipliers (GLM) divergence cleaning technique ([#2215]).
- New time integrator `PairedExplicitRK4`, implementing the fourth-order
  paired explicit Runge-Kutta method with [Convex.jl](https://github.com/jump-dev/Convex.jl)
  and [ECOS.jl](https://github.com/jump-dev/ECOS.jl) ([#2147])
- Passive tracers for arbitrary equations with density and flow variables ([#2364])

#### Deprecated

- The (2D) aerodynamic coefficients
  `DragCoefficientPressure, LiftCoefficientPressure, DragCoefficientShearStress, LiftCoefficientShearStress` have been renamed to
  `DragCoefficientPressure2D, LiftCoefficientPressure2D, DragCoefficientShearStress2D, LiftCoefficientShearStress2D`. ([#2375])

## Changes when updating to v0.11 from v0.10.x

#### Added

#### Changed

- The `CallbackSet` from the OrdinaryDiffEq.jl ecosystem is `export`ed from Trixi.jl ([@2266]).
- The examples switched from OrdinaryDiffEq.jl to its sub-packages such as
  OrdinaryDiffEqLowStorageRK.jl and OrdinaryDiffEqSSPRK.jl ([@2266]). The installation
  instructions for Trixi.jl have been updated accordingly.
- The output of the `SummaryCallback` will automatically be printed after the simulation
  is finished. Therefore, manually calling `summary_callback()` is not necessary anymore ([#2275]).
- The two performance numbers (local `time/DOF/rhs!` and performance index `PID`)
  are now computed taking into account the number of threads ([#2292]). This allows
  for a better comparison of shared memory (threads) and hybrid (MPI + threads) simulations
  with serial simulations.

#### Deprecated

#### Removed


## Changes when updating to v0.10 from v0.9.x

#### Added

#### Changed

- The numerical solution is wrapped in a `VectorOfArrays` from
  [RecursiveArrayTools.jl](https://github.com/SciML/RecursiveArrayTools.jl)
  for `DGMulti` solvers ([#2150]). You can use `Base.parent` to unwrap
  the original data.
- The `PairedExplicitRK2` constructor with second argument `base_path_monomial_coeffs::AbstractString` requires
  now `dt_opt`, `bS`, `cS` to be given as keyword arguments ([#2184]).
  Previously, those where standard function parameters, in the same order as listed above.
- The `AnalysisCallback` output generated with the `save_analysis = true` option now prints
  floating point numbers in their respective (full) precision.
  Previously, only the first 8 digits were printed to file.
  Furthermore, the names of the printed fields are now only separated by a single white space,
  in contrast to before where this were multiple, depending on the actual name of the printed data.
- The boundary conditions for non-conservative equations can now be defined separately from the conservative part.
  The `surface_flux_functions` tuple is now passed directly to the boundary condition call,
  returning a tuple with boundary condition values for both the conservative and non-conservative parts ([#2200]).

#### Deprecated

#### Removed


## Changes in the v0.9 lifecycle

#### Added

- New time integrator `PairedExplicitRK3`, implementing the third-order paired explicit Runge-Kutta
  method with [Convex.jl](https://github.com/jump-dev/Convex.jl), [ECOS.jl](https://github.com/jump-dev/ECOS.jl),
  and [NLsolve.jl](https://github.com/JuliaNLSolvers/NLsolve.jl) ([#2008])
- `LobattoLegendreBasis` and related datastructures made fully floating-type general,
  enabling calculations with higher than double (`Float64`) precision ([#2128])
- In 2D, quadratic elements, i.e., 8-node (quadratic) quadrilaterals are now supported in standard Abaqus `inp` format ([#2217])
- The `cfl` value supplied in the `StepsizeCallback` and `GlmStepsizeCallback` can now be a function of simulation
  time `t` to enable e.g. a ramp-up of the CFL value.
  This is useful for simulations that are initialized with an "unphysical" initial condition, but do not permit the usage of
  adaptive, error-based timestepping.
  Examples for this are simulations involving the MHD equations which require in general the `GlmStepsizeCallback` ([#2248])

#### Changed

- The required Julia version is updated to v1.10.


## Changes when updating to v0.9 from v0.8.x

#### Added

- Boundary conditions are now supported on nonconservative terms ([#2062]).

#### Changed

- We removed the first argument `semi` corresponding to a `Semidiscretization` from the
  `AnalysisSurfaceIntegral` constructor, as it is no longer needed (see [#1959]).
  The `AnalysisSurfaceIntegral` now only takes the arguments `boundary_symbols` and `variable`.
  ([#2069])
- In functions `rhs!`, `rhs_parabolic!`  we removed the unused argument `initial_condition`. ([#2037])
  Users should not be affected by this.
- Nonconservative terms depend only on `normal_direction_average` instead of both
  `normal_direction_average` and `normal_direction_ll`, such that the function signature is now
  identical with conservative fluxes. This required a change of the `normal_direction` in
  `flux_nonconservative_powell` ([#2062]).

#### Deprecated

#### Removed


## Changes in the v0.8 lifecycle

#### Changed

- The AMR routines for `P4estMesh` and `T8codeMesh` were changed to work on the product
  of the Jacobian and the conserved variables instead of the conserved variables only
  to make AMR fully conservative ([#2028]). This may change AMR results slightly.
- Subcell (IDP) limiting is now officially supported and not marked as experimental
  anymore (see `VolumeIntegralSubcellLimiting`).

## Changes when updating to v0.8 from v0.7.x

#### Added

#### Changed

- The specification of boundary names on which `AnalysisSurfaceIntegral`s are computed (such as drag and lift coefficients) has changed from `Symbol` and `Vector{Symbol}` to `NTuple{Symbol}`.
  Thus, for one boundary the syntax changes from `:boundary` to `(:boundary,)` and for `Vector`s `[:boundary1, :boundary2]` to `(:boundary1, :boundary2)` ([#1959]).
- The names of output files like the one created from the `SaveSolutionCallback` have changed from `%06d` to `%09d` to allow longer-running simulations ([#1996]).

#### Deprecated

#### Removed

## Changes in the v0.7 lifecycle

#### Added
- Implementation of `TimeSeriesCallback` for curvilinear meshes on `UnstructuredMesh2D` and extension to 1D and 3D on `TreeMesh` ([#1855], [#1873]).
- Implementation of 1D Linearized Euler Equations ([#1867]).
- New analysis callback for 2D `P4estMesh` to compute integrated quantities along a boundary surface, e.g., pressure lift and drag coefficients ([#1812]).
- Optional tuple parameter for `GlmSpeedCallback` called `semi_indices` to specify for which semidiscretization of a `SemidiscretizationCoupled` we need to update the GLM speed ([#1835]).
- Subcell local one-sided limiting support for nonlinear variables in 2D for `TreeMesh` ([#1792]).
- New time integrator `PairedExplicitRK2`, implementing the second-order paired explicit Runge-Kutta
  method with [Convex.jl](https://github.com/jump-dev/Convex.jl) and [ECOS.jl](https://github.com/jump-dev/ECOS.jl) ([#1908])
- Add subcell limiting support for `StructuredMesh` ([#1946]).

## Changes when updating to v0.7 from v0.6.x

#### Added

#### Changed

- The default wave speed estimate used within `flux_hll` is now `min_max_speed_davis`
  instead of `min_max_speed_naive`.

#### Deprecated

#### Removed
- Some specialized shallow water specific features are no longer available directly in
  Trixi.jl, but are moved to a dedicated repository: [TrixiShallowWater.jl](https://github.com/trixi-framework/TrixiShallowWater.jl). This includes all features related to wetting and drying, as well as the `ShallowWaterTwoLayerEquations1D` and `ShallowWaterTwoLayerEquations2D`.
  However, the basic shallow water equations are still part of Trixi.jl. We'll also be updating the TrixiShallowWater.jl documentation with instructions on how to use these relocated features in the future.


## Changes in the v0.6 lifecycle

#### Added
- AMR for hyperbolic-parabolic equations on 3D `P4estMesh`
- `flux_hllc` on non-cartesian meshes for `CompressibleEulerEquations{2,3}D`
- Different boundary conditions for quad/hex meshes in Abaqus format, even if not generated by HOHQMesh,
  can now be digested by Trixi in 2D and 3D.
- Subcell (positivity) limiting support for nonlinear variables in 2D for `TreeMesh`
- Added Lighthill-Whitham-Richards (LWR) traffic model


## Changes when updating to v0.6 from v0.5.x

#### Added
- AMR for hyperbolic-parabolic equations on 2D `P4estMesh`

#### Changed

- The wave speed estimates for `flux_hll`, `FluxHLL()` are now consistent across equations.
  In particular, the functions `min_max_speed_naive`, `min_max_speed_einfeldt` are now
  conceptually identical across equations.
  Users, who have been using `flux_hll` for MHD have now to use `flux_hlle` in order to use the
  Einfeldt wave speed estimate.
- Parabolic diffusion terms are now officially supported and not marked as experimental
  anymore.

#### Deprecated

#### Removed

- The neural network-based shock indicators have been migrated to a new repository
  [TrixiSmartShockFinder.jl](https://github.com/trixi-framework/TrixiSmartShockFinder.jl).
  To continue using the indicators, you will need to use both Trixi.jl and
  TrixiSmartShockFinder.jl, as explained in the latter packages' `README.md`.


## Changes in the v0.5 lifecycle

#### Added

- Experimental support for 3D parabolic diffusion terms has been added.
- Non-uniform `TreeMesh` available for hyperbolic-parabolic equations.
- Capability to set truly discontinuous initial conditions in 1D.
- Wetting and drying feature and examples for 1D and 2D shallow water equations
- Implementation of the polytropic Euler equations in 2D
- Implementation of the quasi-1D shallow water and compressible Euler equations
- Subcell (positivity and local min/max) limiting support for conservative variables
  in 2D for `TreeMesh`
- AMR for hyperbolic-parabolic equations on 2D/3D `TreeMesh`
- Added `GradientVariables` type parameter to `AbstractEquationsParabolic`

#### Changed

- The required Julia version is updated to v1.8 in Trixi.jl v0.5.13.

#### Deprecated

- The macro `@unpack` (re-exported originally from UnPack.jl) is deprecated and
  will be removed. Consider using Julia's standard destructuring syntax
  `(; a, b) = stuff` instead of `@unpack a, b = stuff`.
- The constructor `DGMultiMesh(dg; cells_per_dimension, kwargs...)` is deprecated
  and will be removed. The new constructor `DGMultiMesh(dg, cells_per_dimension; kwargs...)`
  does not have `cells_per_dimesion` as a keyword argument.

#### Removed

- Migrate neural network-based shock indicators to a new repository
  [TrixiSmartShockFinder.jl](https://github.com/trixi-framework/TrixiSmartShockFinder.jl).


## Changes when updating to v0.5 from v0.4.x

#### Added

#### Changed

- Compile-time boolean indicators have been changed from `Val{true}`/`Val{false}`
  to `Trixi.True`/`Trixi.False`. This affects user code only if new equations
  with nonconservative terms are created. Change
  `Trixi.has_nonconservative_terms(::YourEquations) = Val{true}()` to
  `Trixi.has_nonconservative_terms(::YourEquations) = Trixi.True()`.
- The (non-exported) DGSEM function `split_form_kernel!` has been renamed to `flux_differencing_kernel!`
- Trixi.jl updated its dependency [P4est.jl](https://github.com/trixi-framework/P4est.jl/)
  from v0.3 to v0.4. The new bindings of the C library `p4est` have been
  generated using Clang.jl instead of CBinding.jl v0.9. This affects only user
  code that is interacting directly with `p4est`, e.g., because custom refinement
  functions have been passed to `p4est`. Please consult the
  [NEWS.md of P4est.jl](https://github.com/trixi-framework/P4est.jl/blob/main/NEWS.md)
  for further information.

#### Deprecated

- The signature of the `DGMultiMesh` constructors has changed - the `dg::DGMulti`
  argument now comes first.
- The undocumented and unused
  `DGMultiMesh(triangulateIO, rd::RefElemData{2, Tri}, boundary_dict::Dict{Symbol, Int})`
  constructor was removed.

#### Removed

- Everything deprecated in Trixi.jl v0.4.x has been removed.


## Changes in the v0.4 lifecycle

#### Added

- Implementation of linearized Euler equations in 2D
- Experimental support for upwind finite difference summation by parts (FDSBP)
  has been added in Trixi.jl v0.4.55. The first implementation requires a `TreeMesh` and comes
  with several examples in the `examples_dir()` of Trixi.jl.
- Experimental support for 2D parabolic diffusion terms has been added.
  * `LaplaceDiffusion2D` and `CompressibleNavierStokesDiffusion2D` can be used to add
  diffusion to systems. `LaplaceDiffusion2D` can be used to add scalar diffusion to each
  equation of a system, while `CompressibleNavierStokesDiffusion2D` can be used to add
  Navier-Stokes diffusion to `CompressibleEulerEquations2D`.
  * Parabolic boundary conditions can be imposed as well. For `LaplaceDiffusion2D`, both
  `Dirichlet` and `Neumann` conditions are supported. For `CompressibleNavierStokesDiffusion2D`,
  viscous no-slip velocity boundary conditions are supported, along with adiabatic and isothermal
  temperature boundary conditions. See the boundary condition container
  `BoundaryConditionNavierStokesWall` and boundary condition types `NoSlip`, `Adiabatic`, and
  `Isothermal` for more information.
  * `CompressibleNavierStokesDiffusion2D` can utilize both primitive variables (which are not
  guaranteed to provably dissipate entropy) and entropy variables (which provably dissipate
  entropy at the semi-discrete level).
  * Please check the `examples` directory for further information about the supported setups.
    Further documentation will be added later.
- Numerical fluxes `flux_shima_etal_turbo` and `flux_ranocha_turbo` that are
  equivalent to their non-`_turbo` counterparts but may enable specialized
  methods making use of SIMD instructions to increase runtime efficiency
- Support for (periodic and non-periodic) SBP operators of
  [SummationByPartsOperators.jl](https://github.com/ranocha/SummationByPartsOperators.jl)
  as approximation type in `DGMulti` solvers
- Initial support for MPI-based parallel simulations using non-conforming meshes of type `P4estMesh`
  in 2D and 3D including adaptive mesh refinement

#### Removed

- The `VertexMappedMesh` type is removed in favor of the `DGMultiMesh` type.
  The `VertexMappedMesh` constructor is deprecated.

#### Changed

- The required Julia version is updated to v1.7.
- The isentropic vortex setups contained a bug that was fixed in Trixi.jl v0.4.54.
  Moreover, the setup was made a bit more challenging. See
  https://github.com/trixi-framework/Trixi.jl/issues/1269 for further
  information.

#### Deprecated

- The `DGMultiMesh` constructor which uses a `rd::RefElemData` argument is deprecated in
  favor of the constructor which uses a `dg::DGMulti` argument instead.

## Changes when updating to v0.4 from v0.3.x

#### Added

- Experimental support for artificial neural network-based indicators for shock capturing and
  adaptive mesh refinement ([#632])
- Experimental support for direct-hybrid aeroacoustics simulations ([#712])
- Implementation of shallow water equations in 2D
- Experimental support for interactive visualization with [Makie.jl](https://makie.juliaplots.org/)

#### Changed

- Implementation of acoustic perturbation equations now uses the conservative form, i.e. the
  perturbed pressure `p_prime` has been replaced with `p_prime_scaled = p_prime / c_mean^2`.
- Removed the experimental `BoundaryConditionWall` and instead directly compute slip wall boundary
  condition flux term using the function `boundary_condition_slip_wall`.
- Renamed `advectionvelocity` in `LinearScalarAdvectionEquation` to `advection_velocity`.
- The signature of indicators used for adaptive mesh refinement (AMR) and shock capturing
  changed to generalize them to curved meshes.

#### Deprecated

#### Removed

- Many initial/boundary conditions and source terms for typical setups were
  moved from `Trixi/src` to the example elixirs `Trixi/examples`. Thus, they
  are no longer available when `using Trixi`, e.g., the initial condition
  for the Kelvin Helmholtz instability.
- Features deprecated in v0.3 were removed.


## Changes in the v0.3 lifecycle

#### Added

- Support for automatic differentiation, e.g. `jacobian_ad_forward`
- In-situ visualization and post hoc visualization with Plots.jl
- New systems of equations
  - multicomponent compressible Euler and MHD equations
  - acoustic perturbation equations
  - Lattice-Boltzmann equations
- Composable `FluxPlusDissipation` and `FluxLaxFriedrichs()`, `FluxHLL()` with adaptable
  wave speed estimates were added in [#493]
- New structured, curvilinear, conforming mesh type `StructuredMesh`
- New unstructured, curvilinear, conforming mesh type `UnstructuredMesh2D` in 2D
- New unstructured, curvilinear, adaptive (non-conforming) mesh type `P4estMesh` in 2D and 3D
- Experimental support for finite difference (FD) summation-by-parts (SBP) methods via
  [SummationByPartsOperators.jl](https://github.com/ranocha/SummationByPartsOperators.jl)
- New support for modal DG and SBP-DG methods on triangular and tetrahedral meshes via [StartUpDG.jl](https://github.com/jlchan/StartUpDG.jl)

#### Changed

- `flux_lax_friedrichs(u_ll, u_rr, orientation, equations::LatticeBoltzmannEquations2D)` and
  `flux_lax_friedrichs(u_ll, u_rr, orientation, equations::LatticeBoltzmannEquations3D)`
  were actually using the logic of `flux_godunov`. Thus, they were renamed accordingly
  in [#493]. This is considered a bugfix
  (released in Trixi.jl v0.3.22).
- The required Julia version is updated to v1.6.

#### Deprecated

- `calcflux` → `flux` ([#463])
- `flux_upwind` → `flux_godunov`
- `flux_hindenlang` → `flux_hindenlang_gassner`
- Providing the keyword argument `solution_variables` of `SaveSolutionCallback`
  as `Symbol` is deprecated in favor of using functions like `cons2cons` and
  `cons2prim`
- `varnames_cons(equations)` → `varnames(cons2cons, equations)`
- `varnames_prim(equations)` → `varnames(cons2prim, equations)`
- The old interface for nonconservative terms is deprecated. In particular, passing
  only a single two-point numerical flux for nonconservative is deprecated. The new
  interface is described in a tutorial. Now, a tuple of two numerical fluxes of the
  form `(conservative_flux, nonconservative_flux)` needs to be passed for
  nonconservative equations, see [#657].

#### Removed
