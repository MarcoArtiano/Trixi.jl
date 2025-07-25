using OrdinaryDiffEqLowStorageRK
using Trixi

dg = DGMulti(polydeg = 3, element_type = Tet(), approximation_type = Polynomial(),
             surface_integral = SurfaceIntegralWeakForm(flux_hll),
             volume_integral = VolumeIntegralWeakForm())

equations = CompressibleEulerEquations3D(1.4)
initial_condition = initial_condition_convergence_test
source_terms = source_terms_convergence_test

cells_per_dimension = (4, 4, 4)
mesh = DGMultiMesh(dg, cells_per_dimension, periodicity = true)

semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, dg,
                                    source_terms = source_terms)

tspan = (0.0, 0.1)
ode = semidiscretize(semi, tspan)

summary_callback = SummaryCallback()
alive_callback = AliveCallback(alive_interval = 10)
analysis_interval = 100
analysis_callback = AnalysisCallback(semi, interval = analysis_interval, uEltype = real(dg))
save_solution = SaveSolutionCallback(interval = analysis_interval,
                                     solution_variables = cons2prim)
callbacks = CallbackSet(summary_callback, alive_callback, analysis_callback, save_solution)

###############################################################################
# run the simulation

sol = solve(ode, CarpenterKennedy2N54(williamson_condition = false);
            dt = 0.5 * estimate_dt(mesh, dg), ode_default_options()...,
            callback = callbacks);
