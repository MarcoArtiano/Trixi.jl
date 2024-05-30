
using OrdinaryDiffEq
using Trixi

###############################################################################
# semidiscretization of the compressible Euler equations
gamma = 1.4
equations = CompressibleEulerEquations2D(gamma)

"""
    initial_condition_kelvin_helmholtz_instability(x, t, equations::CompressibleEulerEquations2D)

A version of the classical Kelvin-Helmholtz instability based on
- Andrés M. Rueda-Ramírez, Gregor J. Gassner (2021)
  A Subcell Finite Volume Positivity-Preserving Limiter for DGSEM Discretizations
  of the Euler Equations
  [arXiv: 2102.06017](https://arxiv.org/abs/2102.06017)
"""
function initial_condition_kelvin_helmholtz_instability(x, t,
                                                        equations::CompressibleEulerEquations2D)
    # change discontinuity to tanh
    # typical resolution 128^2, 256^2
    # domain size is [-1,+1]^2
    slope = 15
    amplitude = 0.02
    B = tanh(slope * x[2] + 7.5) - tanh(slope * x[2] - 7.5)
    rho = 0.5 + 0.75 * B
    v1 = 0.5 * (B - 1)
    v2 = 0.1 * sin(2 * pi * x[1])
    p = 1.0
    return prim2cons(SVector(rho, v1, v2, p), equations)
end
initial_condition = initial_condition_kelvin_helmholtz_instability

surface_flux = FluxLMARS(1.7)
# polydeg = 3
polydeg = 3
basis = GaussLegendreBasis(polydeg; polydeg_projection = 2 * polydeg, polydeg_cutoff = 3)
#indicator_sc = IndicatorHennemannGassner(equations, basis,
#                                         alpha_max = 0.000,
#                                         alpha_min = 0.0000,
#                                         alpha_smooth = true,
#                                         variable = density_pressure)
#
#volume_integral = VolumeIntegralShockCapturingHG(indicator_sc;
#                                                 volume_flux_dg = volume_flux,
#                                                 volume_flux_fv = surface_flux)
#volume_integral = VolumeIntegralWeakFormProjection()
volume_integral = VolumeIntegralWeakForm()
solver = DGSEM(basis, surface_flux, volume_integral)

coordinates_min = (-1.0, -1.0)
coordinates_max = (1.0, 1.0)
mesh = TreeMesh(coordinates_min, coordinates_max,
                initial_refinement_level = 6,
                n_cells_max = 100_000)
semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, solver)

###############################################################################
# ODE solvers, callbacks etc.

tspan = (0.0, 3.7)
ode = semidiscretize(semi, tspan)

summary_callback = SummaryCallback()

analysis_interval = 1000
analysis_callback = AnalysisCallback(semi, interval = analysis_interval)

alive_callback = AliveCallback(analysis_interval = analysis_interval)

save_solution = SaveSolutionCallback(interval=1000,
                                     save_initial_solution = true,
                                     save_final_solution = true,
                                     solution_variables = cons2prim)

# stepsize_callback = StepsizeCallback(cfl = 0.5)
stepsize_callback = StepsizeCallback(cfl = 0.5)

#stage_limiter! = PositivityPreservingLimiterZhangShu(thresholds = (5.0e-4, 5.0e-4),
#                                                     variables = (Trixi.density, pressure))

callbacks = CallbackSet(summary_callback,
                        analysis_callback, alive_callback,
                        #save_solution,
                        stepsize_callback)

###############################################################################
# run the simulation

#sol = solve(ode, CarpenterKennedy2N54(williamson_condition = false),
#sol = solve(ode, SSPRK43(stage_limiter!),
sol = solve(ode, SSPRK43(),
            dt = 1.0e-3, # solve needs some value here but it will be overwritten by the stepsize_callback
            save_everystep = false, callback = callbacks);
summary_callback() # print the timer summary