using OrdinaryDiffEqSSPRK
using Trixi

###############################################################################
# semidiscretization of the compressible Euler equations

equations = CompressibleEulerEquations2D(1.4)

p_inf() = 1.0
rho_inf() = p_inf() / (1.0 * 287.87) # p_inf = 1.0,  T = 1, R = 287.87
mach_inf() = 0.85
aoa() = pi / 180.0 # 1 Degree angle of attack
c_inf(equations) = sqrt(equations.gamma * p_inf() / rho_inf())
u_inf(equations) = mach_inf() * c_inf(equations)

# Leave `equations` unspecified here to enable usage of `BoundaryConditionDirichlet(initial_condition)`
# in the "elixir_navierstokes_NACA0012airfoil_mach085_restart.jl" which includes this elixir to
# demonstrate restarting/initializing a hyperbolic-parabolic simulation from a purely hyperbolic simulation.
@inline function initial_condition_mach085_flow(x, t, equations)
    v1 = u_inf(equations) * cos(aoa())
    v2 = u_inf(equations) * sin(aoa())

    prim = SVector(rho_inf(), v1, v2, p_inf())
    return prim2cons(prim, equations)
end

initial_condition = initial_condition_mach085_flow

volume_flux = flux_ranocha_turbo
# Up to version 0.13.0, `max_abs_speed_naive` was used as the default wave speed estimate of
# `const flux_lax_friedrichs = FluxLaxFriedrichs(), i.e., `FluxLaxFriedrichs(max_abs_speed = max_abs_speed_naive)`.
# In the `StepsizeCallback`, though, the less diffusive `max_abs_speeds` is employed which is consistent with `max_abs_speed`.
# Thus, we exchanged in PR#2458 the default wave speed used in the LLF flux to `max_abs_speed`.
# To ensure that every example still runs we specify explicitly `FluxLaxFriedrichs(max_abs_speed_naive)`.
# We remark, however, that the now default `max_abs_speed` is in general recommended due to compliance with the 
# `StepsizeCallback` (CFL-Condition) and less diffusion.
surface_flux = FluxLaxFriedrichs(max_abs_speed_naive)

polydeg = 3
basis = LobattoLegendreBasis(polydeg)
shock_indicator = IndicatorHennemannGassner(equations, basis,
                                            alpha_max = 0.5,
                                            alpha_min = 0.001,
                                            alpha_smooth = true,
                                            variable = density_pressure)
volume_integral = VolumeIntegralShockCapturingHG(shock_indicator;
                                                 volume_flux_dg = volume_flux,
                                                 volume_flux_fv = surface_flux)
solver = DGSEM(polydeg = polydeg, surface_flux = surface_flux,
               volume_integral = volume_integral)

mesh_file = Trixi.download("https://gist.githubusercontent.com/Arpit-Babbar/339662b4b46164a016e35c81c66383bb/raw/8bf94f5b426ba907ace87405cfcc1dcc2ef7cbda/NACA0012.inp",
                           joinpath(@__DIR__, "NACA0012.inp"))

mesh = P4estMesh{2}(mesh_file)

# The outer boundary is constant but subsonic, so we cannot compute the
# boundary flux for the external information alone. Thus, we use the numerical flux to distinguish
# between inflow and outflow characteristics
@inline function boundary_condition_subsonic_constant(u_inner,
                                                      normal_direction::AbstractVector, x,
                                                      t,
                                                      surface_flux_function,
                                                      equations::CompressibleEulerEquations2D)
    u_boundary = initial_condition_mach085_flow(x, t, equations)

    return Trixi.flux_hll(u_inner, u_boundary, normal_direction, equations)
end

boundary_conditions = Dict(:Left => boundary_condition_subsonic_constant,
                           :Right => boundary_condition_subsonic_constant,
                           :Top => boundary_condition_subsonic_constant,
                           :Bottom => boundary_condition_subsonic_constant,
                           :AirfoilBottom => boundary_condition_slip_wall,
                           :AirfoilTop => boundary_condition_slip_wall)

semi = SemidiscretizationHyperbolic(mesh, equations, initial_condition, solver,
                                    boundary_conditions = boundary_conditions)

###############################################################################
# ODE solvers

# Run for a long time to reach a steady state
tspan = (0.0, 20.0)
ode = semidiscretize(semi, tspan)

# Callbacks

summary_callback = SummaryCallback()

analysis_interval = 2000

l_inf = 1.0 # Length of airfoil

force_boundary_names = (:AirfoilBottom, :AirfoilTop)
drag_coefficient = AnalysisSurfaceIntegral(force_boundary_names,
                                           DragCoefficientPressure2D(aoa(), rho_inf(),
                                                                     u_inf(equations),
                                                                     l_inf))

lift_coefficient = AnalysisSurfaceIntegral(force_boundary_names,
                                           LiftCoefficientPressure2D(aoa(), rho_inf(),
                                                                     u_inf(equations),
                                                                     l_inf))

analysis_callback = AnalysisCallback(semi, interval = analysis_interval,
                                     output_directory = "out",
                                     save_analysis = true,
                                     analysis_integrals = (drag_coefficient,
                                                           lift_coefficient))

alive_callback = AliveCallback(analysis_interval = analysis_interval)

save_solution = SaveSolutionCallback(interval = 500,
                                     save_initial_solution = true,
                                     save_final_solution = true,
                                     solution_variables = cons2prim)

stepsize_callback = StepsizeCallback(cfl = 1.0)

amr_indicator = IndicatorLöhner(semi, variable = Trixi.density)

amr_controller = ControllerThreeLevel(semi, amr_indicator,
                                      base_level = 1,
                                      med_level = 3, med_threshold = 0.05,
                                      max_level = 4, max_threshold = 0.1)

amr_interval = 100
amr_callback = AMRCallback(semi, amr_controller,
                           interval = amr_interval,
                           adapt_initial_condition = true,
                           adapt_initial_condition_only_refine = true)

save_restart = SaveRestartCallback(interval = 10_000,
                                   save_final_restart = true)

callbacks = CallbackSet(summary_callback, analysis_callback, alive_callback,
                        save_solution, save_restart,
                        stepsize_callback, amr_callback)

###############################################################################
# run the simulation
sol = solve(ode, SSPRK54(thread = Trixi.True());
            dt = 1.0, # solve needs some value here but it will be overwritten by the stepsize_callback
            ode_default_options()..., callback = callbacks);
