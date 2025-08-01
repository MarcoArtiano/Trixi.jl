"""
    Trixi

**Trixi.jl** is a numerical simulation framework for hyperbolic conservation
laws. A key objective for the framework is to be useful to both scientists
and students. Therefore, next to having an extensible design with a fast
implementation, Trixi.jl is focused on being easy to use for new or inexperienced
users, including the installation and postprocessing procedures.

To get started, run your first simulation with Trixi.jl using

    trixi_include(default_example())

See also: [trixi-framework/Trixi.jl](https://github.com/trixi-framework/Trixi.jl)
"""
module Trixi

using Preferences: @load_preference, set_preferences!
const _PREFERENCE_SQRT = @load_preference("sqrt", "sqrt_Trixi_NaN")
const _PREFERENCE_LOG = @load_preference("log", "log_Trixi_NaN")
const _PREFERENCE_THREADING = Symbol(@load_preference("backend", "polyester"))
const _PREFERENCE_LOOPVECTORIZATION = @load_preference("loop_vectorization", true)

# Include other packages that are used in Trixi.jl
# (standard library packages first, other packages next, all of them sorted alphabetically)

using Accessors: @reset
using LinearAlgebra: LinearAlgebra, Diagonal, diag, dot, eigvals, mul!, norm, cross,
                     normalize, I,
                     UniformScaling, det
using Printf: @printf, @sprintf, println
using SparseArrays: AbstractSparseMatrix, AbstractSparseMatrixCSC, sparse, droptol!,
                    rowvals, nzrange, nonzeros

# import @reexport now to make it available for further imports/exports
using Reexport: @reexport

# MPI needs to be imported before HDF5 to be able to use parallel HDF5
# as long as HDF5.jl uses Requires.jl to enable parallel HDF5 with MPI
using MPI: MPI

@reexport using SciMLBase: CallbackSet
using SciMLBase: DiscreteCallback,
                 ODEProblem, ODESolution,
                 SplitODEProblem
import SciMLBase: get_du, get_tmp_cache, u_modified!,
                  init, step!, check_error,
                  get_proposed_dt, set_proposed_dt!,
                  terminate!, remake, add_tstop!, has_tstop, first_tstop

using DelimitedFiles: readdlm
using Downloads: Downloads
using Adapt: Adapt, adapt
using CodeTracking: CodeTracking
using ConstructionBase: ConstructionBase
using DiffEqBase: DiffEqBase, get_tstops, get_tstops_array
using DiffEqCallbacks: PeriodicCallback, PeriodicCallbackAffect
@reexport using EllipsisNotation # ..
using FillArrays: Ones, Zeros
using ForwardDiff: ForwardDiff
using HDF5: HDF5, h5open, attributes, create_dataset, datatype, dataspace
using KernelAbstractions: KernelAbstractions, @index, @kernel, get_backend, Backend
using LinearMaps: LinearMap
if _PREFERENCE_LOOPVECTORIZATION
    using LoopVectorization: LoopVectorization, @turbo, indices
else
    using LoopVectorization: LoopVectorization, indices
    include("auxiliary/mock_turbo.jl")
end

using StaticArrayInterface: static_length # used by LoopVectorization
using MuladdMacro: @muladd
using Octavian: Octavian, matmul!
using Polyester: Polyester, @batch # You know, the cheapest threads you can find...
using OffsetArrays: OffsetArray, OffsetVector
using P4est
using T8code
using RecipesBase: RecipesBase
using RecursiveArrayTools: VectorOfArray
using Requires: @require
using Static: Static, One, True, False
@reexport using StaticArrays: SVector
using StaticArrays: StaticArrays, MVector, MArray, SMatrix, @SMatrix
using StrideArrays: PtrArray, StrideArray, StaticInt
@reexport using StructArrays: StructArrays, StructArray
using TimerOutputs: TimerOutputs, @notimeit, print_timer, reset_timer!
using Triangulate: Triangulate, TriangulateIO
export TriangulateIO # for type parameter in DGMultiMesh
using TriplotBase: TriplotBase
using TriplotRecipes: DGTriPseudocolor
@reexport using TrixiBase: trixi_include
using TrixiBase: TrixiBase, @trixi_timeit, timer
@reexport using SimpleUnPack: @unpack
using SimpleUnPack: @pack!
using DataStructures: BinaryHeap, FasterForward, extract_all!

using UUIDs: UUID

# finite difference SBP operators
using SummationByPartsOperators: AbstractDerivativeOperator,
                                 AbstractNonperiodicDerivativeOperator,
                                 AbstractPeriodicDerivativeOperator,
                                 grid
import SummationByPartsOperators: integrate, semidiscretize,
                                  compute_coefficients, compute_coefficients!,
                                  left_boundary_weight, right_boundary_weight
@reexport using SummationByPartsOperators: SummationByPartsOperators, derivative_operator,
                                           periodic_derivative_operator,
                                           upwind_operators

# DGMulti solvers
@reexport using StartUpDG: StartUpDG, Polynomial, Gauss, TensorProductWedge, SBP, Line, Tri,
                           Quad, Hex, Tet, Wedge
using StartUpDG: RefElemData, MeshData, AbstractElemShape

# TODO: include_optimized
# This should be used everywhere (except to `include("interpolations.jl")`)
# once the upstream issue https://github.com/timholy/Revise.jl/issues/634
# is fixed; tracked in https://github.com/trixi-framework/Trixi.jl/issues/664.
# # By default, Julia/LLVM does not use fused multiply-add operations (FMAs).
# # Since these FMAs can increase the performance of many numerical algorithms,
# # we need to opt-in explicitly.
# # See https://ranocha.de/blog/Optimizing_EC_Trixi for further details.
# function include_optimized(filename)
#   include(expr -> quote @muladd begin $expr end end, filename)
# end

# Define the entry points of our type hierarchy, e.g.
#     AbstractEquations, AbstractSemidiscretization etc.
# Placing them here allows us to make use of them for dispatch even for
# other stuff defined very early in our include pipeline, e.g.
#     IndicatorLöhner(semi::AbstractSemidiscretization)
include("basic_types.jl")

# Include all top-level source files
include("auxiliary/auxiliary.jl")
include("auxiliary/vector_of_arrays.jl")
include("auxiliary/mpi.jl")
include("auxiliary/p4est.jl")
include("auxiliary/t8code.jl")
include("equations/equations.jl")
include("meshes/meshes.jl")
include("solvers/solvers.jl")
include("equations/equations_parabolic.jl") # these depend on parabolic solver types
include("semidiscretization/semidiscretization.jl")
include("semidiscretization/semidiscretization_hyperbolic.jl")
include("semidiscretization/semidiscretization_hyperbolic_parabolic.jl")
include("semidiscretization/semidiscretization_euler_acoustics.jl")
include("semidiscretization/semidiscretization_coupled.jl")
include("time_integration/time_integration.jl")
include("callbacks_step/callbacks_step.jl")
include("callbacks_stage/callbacks_stage.jl")
include("semidiscretization/semidiscretization_euler_gravity.jl")

# Special elixirs such as `convergence_test`
include("auxiliary/special_elixirs.jl")

# Plot recipes and conversion functions to visualize results with Plots.jl
include("visualization/visualization.jl")

# export types/functions that define the public API of Trixi.jl

export AcousticPerturbationEquations2D,
       CompressibleEulerEquations1D, CompressibleEulerEquations2D,
       CompressibleEulerEquations3D,
       CompressibleEulerMulticomponentEquations1D,
       CompressibleEulerMulticomponentEquations2D,
       CompressibleEulerEquationsQuasi1D,
       IdealGlmMhdEquations1D, IdealGlmMhdEquations2D, IdealGlmMhdEquations3D,
       IdealGlmMhdMulticomponentEquations1D, IdealGlmMhdMulticomponentEquations2D,
       IdealGlmMhdMultiIonEquations2D, IdealGlmMhdMultiIonEquations3D,
       HyperbolicDiffusionEquations1D, HyperbolicDiffusionEquations2D,
       HyperbolicDiffusionEquations3D,
       LinearScalarAdvectionEquation1D, LinearScalarAdvectionEquation2D,
       LinearScalarAdvectionEquation3D,
       InviscidBurgersEquation1D,
       LatticeBoltzmannEquations2D, LatticeBoltzmannEquations3D,
       LinearizedEulerEquations1D, LinearizedEulerEquations2D, LinearizedEulerEquations3D,
       PolytropicEulerEquations2D,
       TrafficFlowLWREquations1D,
       MaxwellEquations1D,
       PassiveTracerEquations

export LaplaceDiffusion1D, LaplaceDiffusion2D, LaplaceDiffusion3D,
       LaplaceDiffusionEntropyVariables1D, LaplaceDiffusionEntropyVariables2D,
       LaplaceDiffusionEntropyVariables3D,
       CompressibleNavierStokesDiffusion1D, CompressibleNavierStokesDiffusion2D,
       CompressibleNavierStokesDiffusion3D

export GradientVariablesConservative, GradientVariablesPrimitive, GradientVariablesEntropy

export flux, flux_central, flux_lax_friedrichs, flux_hll, flux_hllc, flux_hlle,
       flux_godunov,
       flux_chandrashekar, flux_ranocha, flux_derigs_etal, flux_hindenlang_gassner,
       flux_nonconservative_powell, flux_nonconservative_powell_local_symmetric,
       flux_nonconservative_powell_local_jump,
       flux_ruedaramirez_etal, flux_nonconservative_ruedaramirez_etal,
       flux_nonconservative_central,
       flux_kennedy_gruber, flux_shima_etal, flux_ec,
       flux_fjordholm_etal, flux_nonconservative_fjordholm_etal,
       flux_wintermeyer_etal, flux_nonconservative_wintermeyer_etal,
       flux_chan_etal, flux_nonconservative_chan_etal, flux_winters_etal,
       FluxPlusDissipation, DissipationGlobalLaxFriedrichs, DissipationLocalLaxFriedrichs,
       DissipationLaxFriedrichsEntropyVariables, DissipationMatrixWintersEtal,
       FluxLaxFriedrichs, max_abs_speed_naive, max_abs_speed,
       FluxHLL, min_max_speed_naive, min_max_speed_davis, min_max_speed_einfeldt,
       FluxLMARS,
       FluxRotated,
       flux_shima_etal_turbo, flux_ranocha_turbo,
       FluxUpwind,
       FluxTracerEquationsCentral

export splitting_steger_warming, splitting_vanleer_haenel,
       splitting_coirier_vanleer, splitting_lax_friedrichs,
       splitting_drikakis_tsangaris

export initial_condition_constant,
       initial_condition_gauss,
       initial_condition_density_wave,
       initial_condition_weak_blast_wave

export boundary_condition_do_nothing,
       boundary_condition_periodic,
       BoundaryConditionDirichlet,
       BoundaryConditionNeumann,
       boundary_condition_noslip_wall,
       boundary_condition_slip_wall,
       boundary_condition_wall,
       BoundaryConditionNavierStokesWall,
       NoSlip, Slip,
       Adiabatic, Isothermal,
       BoundaryConditionCoupled

export initial_condition_convergence_test, source_terms_convergence_test,
       source_terms_lorentz, source_terms_collision_ion_electron,
       source_terms_collision_ion_ion
export source_terms_harmonic
export initial_condition_poisson_nonperiodic, source_terms_poisson_nonperiodic,
       boundary_condition_poisson_nonperiodic
export initial_condition_eoc_test_coupled_euler_gravity,
       source_terms_eoc_test_coupled_euler_gravity, source_terms_eoc_test_euler

export cons2cons, cons2prim, prim2cons, cons2macroscopic, cons2state, cons2mean,
       cons2entropy, entropy2cons
export density, pressure, density_pressure, velocity, global_mean_vars,
       equilibrium_distribution, waterheight, waterheight_pressure
export entropy, energy_total, energy_kinetic, energy_internal,
       energy_magnetic, cross_helicity, magnetic_field, divergence_cleaning_field,
       enstrophy, vorticity
export lake_at_rest_error
export ncomponents, eachcomponent

export TreeMesh, StructuredMesh, StructuredMeshView, UnstructuredMesh2D, P4estMesh,
       P4estMeshView, T8codeMesh

export DG,
       DGSEM, LobattoLegendreBasis,
       FDSBP,
       VolumeIntegralWeakForm, VolumeIntegralStrongForm,
       VolumeIntegralFluxDifferencing,
       VolumeIntegralPureLGLFiniteVolume,
       VolumeIntegralShockCapturingHG, IndicatorHennemannGassner,
       VolumeIntegralUpwind,
       SurfaceIntegralWeakForm, SurfaceIntegralStrongForm,
       SurfaceIntegralUpwind,
       MortarL2

export VolumeIntegralSubcellLimiting, BoundsCheckCallback,
       SubcellLimiterIDP, SubcellLimiterIDPCorrection

export nelements, nnodes, nvariables,
       eachelement, eachnode, eachvariable,
       get_node_vars

export SemidiscretizationHyperbolic, semidiscretize, compute_coefficients, integrate

export SemidiscretizationHyperbolicParabolic

export SemidiscretizationEulerAcoustics

export SemidiscretizationEulerGravity, ParametersEulerGravity,
       timestep_gravity_erk51_3Sstar!,
       timestep_gravity_erk52_3Sstar!,
       timestep_gravity_erk53_3Sstar!,
       timestep_gravity_carpenter_kennedy_erk54_2N!

export SemidiscretizationCoupled

export SummaryCallback, SteadyStateCallback, AnalysisCallback, AliveCallback,
       SaveRestartCallback, SaveSolutionCallback, TimeSeriesCallback, VisualizationCallback,
       AveragingCallback,
       AMRCallback, StepsizeCallback,
       GlmSpeedCallback, LBMCollisionCallback, EulerAcousticsCouplingCallback,
       TrivialCallback, AnalysisCallbackCoupled,
       AnalysisSurfaceIntegral, DragCoefficientPressure2D, LiftCoefficientPressure2D,
       DragCoefficientShearStress2D, LiftCoefficientShearStress2D,
       DragCoefficientPressure3D, LiftCoefficientPressure3D

export load_mesh, load_time, load_timestep, load_timestep!, load_dt,
       load_adaptive_time_integrator!

export ControllerThreeLevel, ControllerThreeLevelCombined,
       IndicatorLöhner, IndicatorLoehner, IndicatorMax

export PositivityPreservingLimiterZhangShu, EntropyBoundedLimiter

export trixi_include, examples_dir, get_examples, default_example,
       default_example_unstructured, ode_default_options

export ode_norm, ode_unstable_check

export convergence_test, jacobian_fd, jacobian_ad_forward, linear_structure

export DGMulti, DGMultiBasis, estimate_dt, DGMultiMesh, GaussSBP

export ViscousFormulationBassiRebay1, ViscousFormulationLocalDG

# Visualization-related exports
export PlotData1D, PlotData2D, ScalarPlotData2D, getmesh, adapt_to_mesh_level!,
       adapt_to_mesh_level,
       iplot, iplot!

function __init__()
    init_mpi()

    init_p4est()
    init_t8code()

    register_error_hints()

    # Enable features that depend on the availability of the Plots package
    @require Plots="91a5bcdd-55d7-5caf-9e0b-520d859cae80" begin
        using .Plots: Plots
    end
end

include("auxiliary/precompile.jl")
_precompile_manual_()

end
