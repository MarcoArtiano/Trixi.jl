using OrdinaryDiffEqLowStorageRK
using Trixi

# Oscillating Gaussian-shaped source terms
function source_terms_gauss(u, x, t, equations::AcousticPerturbationEquations2D)
    RealT = eltype(u)
    r = convert(RealT, 0.1)
    A = 1
    f = 2

    # Velocity sources
    s1 = 0
    s2 = 0
    # Pressure source
    s3 = exp(-(x[1]^2 + x[2]^2) / (2 * r^2)) * A * sinpi(2 * f * t)

    # Mean sources
    s4 = s5 = s6 = s7 = 0

    return SVector(s1, s2, s3, s4, s5, s6, s7)
end

###############################################################################
# semidiscretization of the acoustic perturbation equations

equations = AcousticPerturbationEquations2D(v_mean_global = (-0.5, 0.25),
                                            c_mean_global = 1.0,
                                            rho_mean_global = 1.0)

initial_condition = initial_condition_constant

# Create DG solver with polynomial degree = 3 and (local) Lax-Friedrichs/Rusanov flux as surface flux

# Up to version 0.13.0, `max_abs_speed_naive` was used as the default wave speed estimate of
# `const flux_lax_friedrichs = FluxLaxFriedrichs(), i.e., `FluxLaxFriedrichs(max_abs_speed = max_abs_speed_naive)`.
# In the `StepsizeCallback`, though, the less diffusive `max_abs_speeds` is employed which is consistent with `max_abs_speed`.
# Thus, we exchanged in PR#2458 the default wave speed used in the LLF flux to `max_abs_speed`.
# To ensure that every example still runs we specify explicitly `FluxLaxFriedrichs(max_abs_speed_naive)`.
# We remark, however, that the now default `max_abs_speed` is in general recommended due to compliance with the 
# `StepsizeCallback` (CFL-Condition) and less diffusion.
solver = DGSEM(polydeg = 3, surface_flux = FluxLaxFriedrichs(max_abs_speed_naive))

coordinates_min = (-3.0, -3.0) # minimum coordinates (min(x), min(y))
coordinates_max = (3.0, 3.0) # maximum coordinates (max(x), max(y))

# Create a uniformly refined mesh with periodic boundaries
mesh = TreeMesh(coordinates_min, coordinates_max,
                initial_refinement_level = 4,
                n_cells_max = 30_000) # set maximum capacity of tree data structure

# A semidiscretization collects data structures and functions for the spatial discretization
semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, solver,
                                    source_terms = source_terms_gauss)

###############################################################################
# ODE solvers, callbacks etc.

# Create ODE problem with time span from 0.0 to 2.0
tspan = (0.0, 2.0)
ode = semidiscretize(semi, tspan)

# At the beginning of the main loop, the SummaryCallback prints a summary of the simulation setup
# and resets the timers
summary_callback = SummaryCallback()

# The AnalysisCallback allows to analyse the solution in regular intervals and prints the results
analysis_callback = AnalysisCallback(semi, interval = 100)

# The SaveSolutionCallback allows to save the solution to a file in regular intervals
save_solution = SaveSolutionCallback(interval = 100,
                                     solution_variables = cons2prim)

# The TimeSeriesCallback records the solution at the given points over time
time_series = TimeSeriesCallback(semi, [(0.0, 0.0), (-1.0, 0.5)])

# The StepsizeCallback handles the re-calculation of the maximum Δt after each time step
stepsize_callback = StepsizeCallback(cfl = 0.5)

# Create a CallbackSet to collect all callbacks such that they can be passed to the ODE solver
callbacks = CallbackSet(summary_callback, analysis_callback, save_solution, time_series,
                        stepsize_callback)

###############################################################################
# run the simulation

# OrdinaryDiffEq's `solve` method evolves the solution in time and executes the passed callbacks
sol = solve(ode, CarpenterKennedy2N54(williamson_condition = false);
            dt = 1.0, # solve needs some value here but it will be overwritten by the stepsize_callback
            ode_default_options()..., callback = callbacks);
