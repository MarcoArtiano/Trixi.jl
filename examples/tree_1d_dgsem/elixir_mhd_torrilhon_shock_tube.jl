using OrdinaryDiffEqLowStorageRK
using Trixi

###############################################################################
# semidiscretization of the ideal MHD equations
gamma = 5 / 3
equations = IdealGlmMhdEquations1D(gamma)

"""
    initial_condition_torrilhon_shock_tube(x, t, equations::IdealGlmMhdEquations1D)

Torrilhon's shock tube test case for one dimensional ideal MHD equations.
- Torrilhon (2003)
  Uniqueness conditions for Riemann problems of ideal magnetohydrodynamics
  [DOI: 10.1017/S0022377803002186](https://doi.org/10.1017/S0022377803002186)
"""
function initial_condition_torrilhon_shock_tube(x, t, equations::IdealGlmMhdEquations1D)
    # domain must be set to [-1, 1.5], γ = 5/3, final time = 0.4
    RealT = eltype(x)
    rho = x[1] <= 0 ? 3 : 1
    v1 = 0
    v2 = 0
    v3 = 0
    p = x[1] <= 0 ? 3 : 1
    B1 = 1.5f0
    B2 = x[1] <= 0 ? one(RealT) : cos(RealT(1.5f0))
    B3 = x[1] <= 0 ? zero(RealT) : sin(RealT(1.5f0))
    return prim2cons(SVector(rho, v1, v2, v3, p, B1, B2, B3), equations)
end
initial_condition = initial_condition_torrilhon_shock_tube

boundary_conditions = BoundaryConditionDirichlet(initial_condition)

# Up to version 0.13.0, `max_abs_speed_naive` was used as the default wave speed estimate of
# `const flux_lax_friedrichs = FluxLaxFriedrichs(), i.e., `FluxLaxFriedrichs(max_abs_speed = max_abs_speed_naive)`.
# In the `StepsizeCallback`, though, the less diffusive `max_abs_speeds` is employed which is consistent with `max_abs_speed`.
# Thus, we exchanged in PR#2458 the default wave speed used in the LLF flux to `max_abs_speed`.
# To ensure that every example still runs we specify explicitly `FluxLaxFriedrichs(max_abs_speed_naive)`.
# We remark, however, that the now default `max_abs_speed` is in general recommended due to compliance with the 
# `StepsizeCallback` (CFL-Condition) and less diffusion.
surface_flux = FluxLaxFriedrichs(max_abs_speed_naive)
volume_flux = flux_central
basis = LobattoLegendreBasis(3)

indicator_sc = IndicatorHennemannGassner(equations, basis,
                                         alpha_max = 0.5,
                                         alpha_min = 0.001,
                                         alpha_smooth = true,
                                         variable = pressure)
volume_integral = VolumeIntegralShockCapturingHG(indicator_sc;
                                                 volume_flux_dg = volume_flux,
                                                 volume_flux_fv = surface_flux)
solver = DGSEM(basis, surface_flux, volume_integral)

coordinates_min = -1.0
coordinates_max = 1.5
mesh = TreeMesh(coordinates_min, coordinates_max,
                initial_refinement_level = 7,
                n_cells_max = 10_000,
                periodicity = false)

semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, solver,
                                    boundary_conditions = boundary_conditions)

###############################################################################
# ODE solvers, callbacks etc.

tspan = (0.0, 0.4)
ode = semidiscretize(semi, tspan)

summary_callback = SummaryCallback()

analysis_interval = 100
analysis_callback = AnalysisCallback(semi, interval = analysis_interval,
                                     extra_analysis_errors = (:l2_error_primitive,
                                                              :linf_error_primitive))

alive_callback = AliveCallback(analysis_interval = analysis_interval)

save_solution = SaveSolutionCallback(interval = 100,
                                     save_initial_solution = true,
                                     save_final_solution = true,
                                     solution_variables = cons2prim)

stepsize_callback = StepsizeCallback(cfl = 1.0)

callbacks = CallbackSet(summary_callback,
                        analysis_callback, alive_callback,
                        save_solution,
                        stepsize_callback)

###############################################################################
# run the simulation

sol = solve(ode, CarpenterKennedy2N54(williamson_condition = false);
            dt = 1.0, # solve needs some value here but it will be overwritten by the stepsize_callback
            ode_default_options()..., callback = callbacks);
