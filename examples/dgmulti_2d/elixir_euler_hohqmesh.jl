using OrdinaryDiffEqLowStorageRK
using Trixi

# This is a DGMulti version of the UnstructuredMesh2D elixir `elixir_euler_basic.jl`,
# which can be found at `examples/unstructured_2d_dgsem/elixir_euler_basic.jl`.

###############################################################################
# semidiscretization of the compressible Euler equations

equations = CompressibleEulerEquations2D(1.4)

initial_condition = initial_condition_convergence_test
source_terms = source_terms_convergence_test

boundary_condition_convergence_test = BoundaryConditionDirichlet(initial_condition)
boundary_conditions = (; :Slant => boundary_condition_convergence_test,
                       :Bezier => boundary_condition_convergence_test,
                       :Right => boundary_condition_convergence_test,
                       :Bottom => boundary_condition_convergence_test,
                       :Top => boundary_condition_convergence_test)

###############################################################################
# Get the DG approximation space

# Up to version 0.13.0, `max_abs_speed_naive` was used as the default wave speed estimate of
# `const flux_lax_friedrichs = FluxLaxFriedrichs(), i.e., `FluxLaxFriedrichs(max_abs_speed = max_abs_speed_naive)`.
# In the `StepsizeCallback`, though, the less diffusive `max_abs_speeds` is employed which is consistent with `max_abs_speed`.
# Thus, we exchanged in PR#2458 the default wave speed used in the LLF flux to `max_abs_speed`.
# To ensure that every example still runs we specify explicitly `FluxLaxFriedrichs(max_abs_speed_naive)`.
# We remark, however, that the now default `max_abs_speed` is in general recommended due to compliance with the 
# `StepsizeCallback` (CFL-Condition) and less diffusion.
dg = DGMulti(polydeg = 8, element_type = Quad(), approximation_type = SBP(),
             surface_integral = SurfaceIntegralWeakForm(FluxLaxFriedrichs(max_abs_speed_naive)),
             volume_integral = VolumeIntegralFluxDifferencing(flux_ranocha))

###############################################################################
# Get the curved quad mesh from a file (downloads the file if not available locally)
mesh_file = Trixi.download("https://gist.githubusercontent.com/andrewwinters5000/52056f1487853fab63b7f4ed7f171c80/raw/9d573387dfdbb8bce2a55db7246f4207663ac07f/mesh_trixi_unstructured_mesh_docs.mesh",
                           joinpath(@__DIR__, "mesh_trixi_unstructured_mesh_docs.mesh"))

mesh = DGMultiMesh(dg, mesh_file)

###############################################################################
# create the semi discretization object

semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, dg,
                                    source_terms = source_terms,
                                    boundary_conditions = boundary_conditions)

###############################################################################
# ODE solvers, callbacks etc.

tspan = (0.0, 3.0)
ode = semidiscretize(semi, tspan)

summary_callback = SummaryCallback()

analysis_interval = 100
analysis_callback = AnalysisCallback(semi, interval = analysis_interval, uEltype = real(dg))

alive_callback = AliveCallback(analysis_interval = analysis_interval)

save_solution = SaveSolutionCallback(interval = analysis_interval,
                                     solution_variables = cons2prim)

callbacks = CallbackSet(summary_callback,
                        analysis_callback,
                        alive_callback, save_solution)

###############################################################################
# run the simulation

time_int_tol = 1e-8
sol = solve(ode, RDPK3SpFSAL49(); abstol = time_int_tol, reltol = time_int_tol,
            dt = time_int_tol, ode_default_options()..., callback = callbacks)
