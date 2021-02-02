
using OrdinaryDiffEq
using Trixi

###############################################################################
# semidiscretization of the linear advection equation

nu = 4.8e-1
equations = HeatEquation2D(nu)

# Create DG solver with polynomial degree = 3 and the central flux as surface flux
solver = DGSEM(3, flux_central)

coordinates_min = (-4, -4) # minimum coordinates (min(x), min(y))
coordinates_max = ( 4,  4) # maximum coordinates (max(x), max(y))

# Create a uniformely refined mesh with periodic boundaries
mesh = TreeMesh(coordinates_min, coordinates_max,
                initial_refinement_level=3,
                n_cells_max=30_000) # set maximum capacity of tree data structure

# A semidiscretization collects data structures and functions for the spatial discretization
initial_condition = initial_condition_gauss
semi = SemidiscretizationParabolicAuxVars(mesh, equations, initial_condition, solver)


###############################################################################
# ODE solvers, callbacks etc.

# Create ODE problem with time span from 0.0 to 1.0
tspan = (0.0, 1.0)
ode = semidiscretize(semi, tspan);

# At the beginning of the main loop, the SummaryCallback prints a summary of the simulation setup
# and resets the timers
summary_callback = SummaryCallback()

# The AnalysisCallback allows to analyse the solution in regular intervals and prints the results
analysis_callback = AnalysisCallback(semi, interval=100)

# The SaveSolutionCallback allows to save the solution to a file in regular intervals
save_solution = SaveSolutionCallback(interval=100,
                                     solution_variables=cons2prim)

amr_controller = ControllerThreeLevel(semi, IndicatorMax(semi, variable=first),
                                      base_level=3,
                                      med_level=4, med_threshold=0.05,
                                      max_level=5, max_threshold=0.3)
amr_callback = AMRCallback(semi, amr_controller,
                           interval=5,
                           adapt_initial_condition=true,
                           adapt_initial_condition_only_refine=true)

# The StepsizeCallback handles the re-calculcation of the maximum Δt after each time step
stepsize_callback = StepsizeCallback(cfl=0.5)

# Create a CallbackSet to collect all callbacks such that they can be passed to the ODE solver
callbacks = CallbackSet(summary_callback, analysis_callback, save_solution, amr_callback,
                        stepsize_callback)


###############################################################################
# run the simulation

# OrdinaryDiffEq's `solve` method evolves the solution in time and executes the passed callbacks
sol = solve(ode, CarpenterKennedy2N54(williamson_condition=false),
            dt=1.0, # solve needs some value here but it will be overwritten by the stepsize_callback
            save_everystep=false, callback=callbacks, maxiters=1e5);

# Print the timer summary
summary_callback()
