using OrdinaryDiffEqLowStorageRK
using Trixi

###############################################################################
# semidiscretization of the compressible Euler equations
gamma = 5 / 3
equations = CompressibleEulerEquations2D(gamma)

"""
    initial_condition_blob(x, t, equations::CompressibleEulerEquations2D)

The blob test case taken from
- Agertz et al. (2006)
  Fundamental differences between SPH and grid methods
  [arXiv: astro-ph/0610051](https://arxiv.org/abs/astro-ph/0610051)
"""
function initial_condition_blob(x, t, equations::CompressibleEulerEquations2D)
    # blob test case, see Agertz et al. https://arxiv.org/pdf/astro-ph/0610051.pdf
    # other reference: https://doi.org/10.1111/j.1365-2966.2007.12183.x
    # change discontinuity to tanh
    # typical domain is rectangular, we change it to a square
    # resolution 128^2, 256^2
    # domain size is [-20.0,20.0]^2
    # gamma = 5/3 for this test case
    RealT = eltype(x)
    R = 1 # radius of the blob
    # background density
    dens0 = 1
    Chi = convert(RealT, 10) # density contrast
    # reference time of characteristic growth of KH instability equal to 1.0
    tau_kh = 1
    tau_cr = tau_kh / convert(RealT, 1.6) # crushing time
    # determine background velocity
    velx0 = 2 * R * sqrt(Chi) / tau_cr
    vely0 = 0
    Ma0 = convert(RealT, 2.7) # background flow Mach number Ma=v/c
    c = velx0 / Ma0 # sound speed
    # use perfect gas assumption to compute background pressure via the sound speed c^2 = gamma * pressure/density
    p0 = c * c * dens0 / equations.gamma
    # initial center of the blob
    inicenter = [-15, 0]
    x_rel = x - inicenter
    r = sqrt(x_rel[1]^2 + x_rel[2]^2)
    # steepness of the tanh transition zone
    slope = 2
    # density blob
    dens = dens0 +
           (Chi - 1) * 0.5f0 * (1 + (tanh(slope * (r + R)) - (tanh(slope * (r - R)) + 1)))
    # velocity blob is zero
    velx = velx0 -
           velx0 * 0.5f0 * (1 + (tanh(slope * (r + R)) - (tanh(slope * (r - R)) + 1)))
    return prim2cons(SVector(dens, velx, vely0, p0), equations)
end
initial_condition = initial_condition_blob

# Up to version 0.13.0, `max_abs_speed_naive` was used as the default wave speed estimate of
# `const flux_lax_friedrichs = FluxLaxFriedrichs(), i.e., `FluxLaxFriedrichs(max_abs_speed = max_abs_speed_naive)`.
# In the `StepsizeCallback`, though, the less diffusive `max_abs_speeds` is employed which is consistent with `max_abs_speed`.
# Thus, we exchanged in PR#2458 the default wave speed used in the LLF flux to `max_abs_speed`.
# To ensure that every example still runs we specify explicitly `FluxLaxFriedrichs(max_abs_speed_naive)`.
# We remark, however, that the now default `max_abs_speed` is in general recommended due to compliance with the 
# `StepsizeCallback` (CFL-Condition) and less diffusion.
surface_flux = FluxLaxFriedrichs(max_abs_speed_naive)
volume_flux = flux_ranocha
basis = LobattoLegendreBasis(3)

indicator_sc = IndicatorHennemannGassner(equations, basis,
                                         alpha_max = 0.05,
                                         alpha_min = 0.0001,
                                         alpha_smooth = true,
                                         variable = pressure)

volume_integral = VolumeIntegralShockCapturingHG(indicator_sc;
                                                 volume_flux_dg = volume_flux,
                                                 volume_flux_fv = surface_flux)

solver = DGSEM(basis, surface_flux, volume_integral)

coordinates_min = (-32.0, -32.0)
coordinates_max = (32.0, 32.0)
refinement_patches = ((type = "box", coordinates_min = (-40.0, -5.0),
                       coordinates_max = (40.0, 5.0)),
                      (type = "box", coordinates_min = (-40.0, -5.0),
                       coordinates_max = (40.0, 5.0)))
mesh = TreeMesh(coordinates_min, coordinates_max,
                initial_refinement_level = 4,
                refinement_patches = refinement_patches,
                n_cells_max = 100_000)

semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, solver)

###############################################################################
# ODE solvers, callbacks etc.

tspan = (0.0, 16.0)
ode = semidiscretize(semi, tspan)

summary_callback = SummaryCallback()

analysis_interval = 100
analysis_callback = AnalysisCallback(semi, interval = analysis_interval)

alive_callback = AliveCallback(analysis_interval = analysis_interval)

save_solution = SaveSolutionCallback(interval = 100,
                                     save_initial_solution = true,
                                     save_final_solution = true,
                                     solution_variables = cons2prim)

stepsize_callback = StepsizeCallback(cfl = 0.7)

callbacks = CallbackSet(summary_callback,
                        analysis_callback, alive_callback,
                        save_solution,
                        stepsize_callback)

###############################################################################
# run the simulation

sol = solve(ode, CarpenterKennedy2N54(williamson_condition = false);
            dt = 1.0, # solve needs some value here but it will be overwritten by the stepsize_callback
            ode_default_options()..., callback = callbacks);
