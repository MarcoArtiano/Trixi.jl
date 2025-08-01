module TestUnit

using Test
using Trixi

using LinearAlgebra: norm, dot
using DelimitedFiles: readdlm

# Use Convex and ECOS to load the extension that extends functions for testing
# PERK Single p2 Constructors
using Convex: Convex
using ECOS: Optimizer

# Use NLsolve to load the extension that extends functions for testing
# PERK Single p3 Constructors
using NLsolve: nlsolve

include("test_trixi.jl")

# Start with a clean environment: remove Trixi.jl output directory if it exists
outdir = "out"
isdir(outdir) && rm(outdir, recursive = true)

# Run various unit (= non-elixir-triggered) tests
@testset "Unit tests" begin
#! format: noindent

@timed_testset "SerialTree" begin
    @testset "constructors" begin
        @test_nowarn Trixi.SerialTree(Val(1), 10, 0.0, 1.0)
        @test_nowarn Trixi.SerialTree{1}(10, 0.0, 1.0)
    end

    @testset "helper functions" begin
        t = Trixi.SerialTree(Val(1), 10, 0.0, 1.0)
        @test_nowarn display(t)
        @test Trixi.ndims(t) == 1
        @test Trixi.has_any_neighbor(t, 1, 1) == true
        @test Trixi.isperiodic(t, 1) == true
        @test Trixi.n_children_per_cell(t) == 2
        @test Trixi.n_directions(t) == 2
    end

    @testset "refine!/coarsen!" begin
        t = Trixi.SerialTree(Val(1), 10, 0.0, 1.0)
        @test Trixi.refine!(t) == [1]
        @test Trixi.coarsen!(t) == [1]
        @test Trixi.refine!(t) == [1]
        @test Trixi.coarsen!(t, 1) == [1]
        @test Trixi.coarsen!(t) == Int[] # Coarsen twice to check degenerate case of single-cell tree
        @test Trixi.refine!(t) == [1]
        @test Trixi.refine!(t) == [2, 3]
        @test Trixi.coarsen_box!(t, [-0.5], [0.0]) == [2]
        @test Trixi.coarsen_box!(t, 0.0, 0.5) == [3]
        @test isnothing(Trixi.reset_data_structures!(t))
    end
end

@timed_testset "ParallelTree" begin
    @testset "constructors" begin
        @test_nowarn Trixi.ParallelTree(Val(1), 10, 0.0, 1.0)
        @test_nowarn Trixi.ParallelTree{1}(10, 0.0, 1.0)
    end

    @testset "helper functions" begin
        t = Trixi.ParallelTree(Val(1), 10, 0.0, 1.0)
        @test isnothing(display(t))
        @test isnothing(Trixi.reset_data_structures!(t))
    end
end

@timed_testset "TreeMesh" begin
    @testset "constructors" begin
        @test TreeMesh{1, Trixi.SerialTree{1, Float64}, Float64}(1, 5.0, 2.0) isa
              TreeMesh

        # Invalid domain length check (TreeMesh expects a hypercube)
        # 2D
        @test_throws ArgumentError TreeMesh((-0.5, 0.0), (1.0, 2.0),
                                            initial_refinement_level = 2,
                                            n_cells_max = 10_000)
        # 3D
        @test_throws ArgumentError TreeMesh((-0.5, 0.0, -0.2), (1.0, 2.0, 1.5),
                                            initial_refinement_level = 2,
                                            n_cells_max = 10_000)
    end
end

@timed_testset "ParallelTreeMesh" begin
    @testset "partition!" begin
        @testset "mpi_nranks() = 2" begin
            Trixi.mpi_nranks() = 2
            let
                @test Trixi.mpi_nranks() == 2

                mesh = TreeMesh{2, Trixi.ParallelTree{2, Float64}, Float64}(30,
                                                                            (0.0, 0.0),
                                                                            1.0)
                # Refine twice
                Trixi.refine!(mesh.tree)
                Trixi.refine!(mesh.tree)

                # allow_coarsening = true
                Trixi.partition!(mesh)
                # Use parent for OffsetArray
                @test parent(mesh.n_cells_by_rank) == [11, 10]
                @test mesh.tree.mpi_ranks[1:21] ==
                      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
                @test parent(mesh.first_cell_by_rank) == [1, 12]

                # allow_coarsening = false
                Trixi.partition!(mesh; allow_coarsening = false)
                @test parent(mesh.n_cells_by_rank) == [11, 10]
                @test mesh.tree.mpi_ranks[1:21] ==
                      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]
                @test parent(mesh.first_cell_by_rank) == [1, 12]
            end
            Trixi.mpi_nranks() = Trixi.MPI_SIZE[] # restore the original behavior
        end

        @testset "mpi_nranks() = 3" begin
            Trixi.mpi_nranks() = 3
            let
                @test Trixi.mpi_nranks() == 3

                mesh = TreeMesh{2, Trixi.ParallelTree{2, Float64}, Float64}(100,
                                                                            (0.0, 0.0),
                                                                            1.0)
                # Refine twice
                Trixi.refine!(mesh.tree)
                Trixi.refine!(mesh.tree)

                # allow_coarsening = true
                Trixi.partition!(mesh)
                # Use parent for OffsetArray
                @test parent(mesh.n_cells_by_rank) == [11, 5, 5]
                @test mesh.tree.mpi_ranks[1:21] ==
                      [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2]
                @test parent(mesh.first_cell_by_rank) == [1, 12, 17]

                # allow_coarsening = false
                Trixi.partition!(mesh; allow_coarsening = false)
                @test parent(mesh.n_cells_by_rank) == [9, 6, 6]
                @test mesh.tree.mpi_ranks[1:21] ==
                      [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 2, 2]
                @test parent(mesh.first_cell_by_rank) == [1, 10, 16]
            end
            Trixi.mpi_nranks() = Trixi.MPI_SIZE[] # restore the original behavior
        end

        @testset "mpi_nranks() = 9" begin
            Trixi.mpi_nranks() = 9
            let
                @test Trixi.mpi_nranks() == 9

                mesh = TreeMesh{2, Trixi.ParallelTree{2, Float64}, Float64}(1000,
                                                                            (0.0, 0.0),
                                                                            1.0)
                # Refine twice
                Trixi.refine!(mesh.tree)
                Trixi.refine!(mesh.tree)
                Trixi.refine!(mesh.tree)
                Trixi.refine!(mesh.tree)

                # allow_coarsening = true
                Trixi.partition!(mesh)
                # Use parent for OffsetArray
                @test parent(mesh.n_cells_by_rank) ==
                      [44, 37, 38, 37, 37, 37, 38, 37, 36]
                @test parent(mesh.first_cell_by_rank) ==
                      [1, 45, 82, 120, 157, 194, 231, 269, 306]
            end
            Trixi.mpi_nranks() = Trixi.MPI_SIZE[] # restore the original behavior
        end

        @testset "mpi_nranks() = 3 non-uniform" begin
            Trixi.mpi_nranks() = 3
            let
                @test Trixi.mpi_nranks() == 3

                mesh = TreeMesh{2, Trixi.ParallelTree{2, Float64}, Float64}(100,
                                                                            (0.0, 0.0),
                                                                            1.0)
                # Refine whole tree
                Trixi.refine!(mesh.tree)
                # Refine left leaf
                Trixi.refine!(mesh.tree, [2])

                # allow_coarsening = true
                Trixi.partition!(mesh)
                # Use parent for OffsetArray
                @test parent(mesh.n_cells_by_rank) == [6, 1, 2]
                @test mesh.tree.mpi_ranks[1:9] == [0, 0, 0, 0, 0, 0, 1, 2, 2]
                @test parent(mesh.first_cell_by_rank) == [1, 7, 8]

                # allow_coarsening = false
                Trixi.partition!(mesh; allow_coarsening = false)
                @test parent(mesh.n_cells_by_rank) == [5, 2, 2]
                @test mesh.tree.mpi_ranks[1:9] == [0, 0, 0, 0, 0, 1, 1, 2, 2]
                @test parent(mesh.first_cell_by_rank) == [1, 6, 8]
            end
            Trixi.mpi_nranks() = Trixi.MPI_SIZE[] # restore the original behavior
        end

        @testset "not enough ranks" begin
            Trixi.mpi_nranks() = 3
            let
                @test Trixi.mpi_nranks() == 3

                mesh = TreeMesh{2, Trixi.ParallelTree{2, Float64}, Float64}(100,
                                                                            (0.0, 0.0),
                                                                            1.0)

                # Only one leaf
                @test_throws AssertionError("Too many ranks to properly partition the mesh!") Trixi.partition!(mesh)

                # Refine to 4 leaves
                Trixi.refine!(mesh.tree)

                # All four leaves will need to be on one rank to allow coarsening
                @test_throws AssertionError("Too many ranks to properly partition the mesh!") Trixi.partition!(mesh)
                @test_nowarn Trixi.partition!(mesh; allow_coarsening = false)
            end
            Trixi.mpi_nranks() = Trixi.MPI_SIZE[] # restore the original behavior
        end
    end
end

@timed_testset "curved mesh" begin
    @testset "calc_jacobian_matrix" begin
        @testset "identity map" begin
            basis = LobattoLegendreBasis(5)
            nodes = Trixi.get_nodes(basis)
            jacobian_matrix = Array{Float64, 5}(undef, 2, 2, 6, 6, 1)

            node_coordinates = Array{Float64, 4}(undef, 2, 6, 6, 1)
            node_coordinates[1, :, :, 1] .= [nodes[i] for i in 1:6, j in 1:6]
            node_coordinates[2, :, :, 1] .= [nodes[j] for i in 1:6, j in 1:6]
            expected = zeros(2, 2, 6, 6, 1)
            expected[1, 1, :, :, 1] .= 1
            expected[2, 2, :, :, 1] .= 1
            @test Trixi.calc_jacobian_matrix!(jacobian_matrix, 1, node_coordinates,
                                              basis) ≈ expected
        end

        @testset "maximum exact polydeg" begin
            basis = LobattoLegendreBasis(3)
            nodes = Trixi.get_nodes(basis)
            jacobian_matrix = Array{Float64, 5}(undef, 2, 2, 4, 4, 1)

            # f(x, y) = [x^3, xy^2]
            node_coordinates = Array{Float64, 4}(undef, 2, 4, 4, 1)
            node_coordinates[1, :, :, 1] .= [nodes[i]^3 for i in 1:4, j in 1:4]
            node_coordinates[2, :, :, 1] .= [nodes[i] * nodes[j]^2
                                             for i in 1:4, j in 1:4]

            # Df(x, y) = [3x^2 0;
            #              y^2 2xy]
            expected = zeros(2, 2, 4, 4, 1)
            expected[1, 1, :, :, 1] .= [3 * nodes[i]^2 for i in 1:4, j in 1:4]
            expected[2, 1, :, :, 1] .= [nodes[j]^2 for i in 1:4, j in 1:4]
            expected[2, 2, :, :, 1] .= [2 * nodes[i] * nodes[j] for i in 1:4, j in 1:4]
            @test Trixi.calc_jacobian_matrix!(jacobian_matrix, 1, node_coordinates,
                                              basis) ≈ expected
        end
    end
end

@timed_testset "interpolation" begin
    @testset "nodes and weights" begin
        @test Trixi.gauss_nodes_weights(1) == ([0.0], [2.0])

        @test Trixi.gauss_nodes_weights(2)[1] ≈ [-1 / sqrt(3), 1 / sqrt(3)]
        @test Trixi.gauss_nodes_weights(2)[2] == [1.0, 1.0]

        @test Trixi.gauss_nodes_weights(3)[1] ≈ [-sqrt(3 / 5), 0.0, sqrt(3 / 5)]
        @test Trixi.gauss_nodes_weights(3)[2] ≈ [5 / 9, 8 / 9, 5 / 9]
    end

    @testset "multiply_dimensionwise" begin
        nodes_in = [0.0, 0.5, 1.0]
        nodes_out = [0.0, 1 / 3, 2 / 3, 1.0]
        matrix = Trixi.polynomial_interpolation_matrix(nodes_in, nodes_out)
        data_in = [3.0 4.5 6.0]
        @test isapprox(Trixi.multiply_dimensionwise(matrix, data_in), [3.0 4.0 5.0 6.0])

        n_vars = 3
        size_in = 2
        size_out = 3
        matrix = randn(size_out, size_in)
        # 1D
        data_in = randn(n_vars, size_in)
        data_out = Trixi.multiply_dimensionwise_naive(matrix, data_in)
        @test isapprox(data_out, Trixi.multiply_dimensionwise(matrix, data_in))
        # 2D
        data_in = randn(n_vars, size_in, size_in)
        data_out = Trixi.multiply_dimensionwise_naive(matrix, data_in)
        @test isapprox(data_out, Trixi.multiply_dimensionwise(matrix, data_in))
        # 3D
        data_in = randn(n_vars, size_in, size_in, size_in)
        data_out = Trixi.multiply_dimensionwise_naive(matrix, data_in)
        @test isapprox(data_out, Trixi.multiply_dimensionwise(matrix, data_in))
    end
end

@timed_testset "L2 projection" begin
    @testset "calc_reverse_upper for LGL" begin
        @test isapprox(Trixi.calc_reverse_upper(2, Val(:gauss_lobatto)),
                       [[0.25, 0.25] [0.0, 0.5]])
    end
    @testset "calc_reverse_lower for LGL" begin
        @test isapprox(Trixi.calc_reverse_lower(2, Val(:gauss_lobatto)),
                       [[0.5, 0.0] [0.25, 0.25]])
    end
end

@testset "containers" begin
    # Set up mock container
    mutable struct MyContainer <: Trixi.AbstractContainer
        data::Vector{Int}
        capacity::Int
        length::Int
        dummy::Int
    end
    function MyContainer(data, capacity)
        c = MyContainer(Vector{Int}(undef, capacity + 1), capacity, length(data),
                        capacity + 1)
        c.data[eachindex(data)] .= data
        return c
    end
    MyContainer(data::AbstractArray) = MyContainer(data, length(data))
    Trixi.invalidate!(c::MyContainer, first, last) = (c.data[first:last] .= 0; c)
    function Trixi.raw_copy!(target::MyContainer, source::MyContainer, first, last,
                             destination)
        Trixi.copy_data!(target.data, source.data, first, last, destination)
        return target
    end
    Trixi.move_connectivity!(c::MyContainer, first, last, destination) = c
    Trixi.delete_connectivity!(c::MyContainer, first, last) = c
    function Trixi.reset_data_structures!(c::MyContainer)
        (c.data = Vector{Int}(undef,
                              c.capacity + 1);
         c)
    end
    function Base.:(==)(c1::MyContainer, c2::MyContainer)
        return (c1.capacity == c2.capacity &&
                c1.length == c2.length &&
                c1.dummy == c2.dummy &&
                c1.data[1:(c1.length)] == c2.data[1:(c2.length)])
    end

    @testset "size" begin
        c = MyContainer([1, 2, 3])
        @test size(c) == (3,)
    end

    @testset "resize!" begin
        c = MyContainer([1, 2, 3])
        @test length(resize!(c, 2)) == 2
    end

    @testset "copy!" begin
        c1 = MyContainer([1, 2, 3])
        c2 = MyContainer([4, 5])
        @test Trixi.copy!(c1, c2, 2, 1, 2) == MyContainer([1, 2, 3]) # no-op

        c1 = MyContainer([1, 2, 3])
        c2 = MyContainer([4, 5])
        @test Trixi.copy!(c1, c2, 1, 2, 2) == MyContainer([1, 4, 5])

        c1 = MyContainer([1, 2, 3])
        @test Trixi.copy!(c1, c2, 1, 2) == MyContainer([1, 4, 3])

        c1 = MyContainer([1, 2, 3])
        @test Trixi.copy!(c1, 2, 3, 1) == MyContainer([2, 3, 3])

        c1 = MyContainer([1, 2, 3])
        @test Trixi.copy!(c1, 1, 3) == MyContainer([1, 2, 1])
    end

    @testset "move!" begin
        c = MyContainer([1, 2, 3])
        @test Trixi.move!(c, 1, 1) == MyContainer([1, 2, 3]) # no-op

        c = MyContainer([1, 2, 3])
        @test Trixi.move!(c, 1, 2) == MyContainer([0, 1, 3])
    end

    @testset "swap!" begin
        c = MyContainer([1, 2])
        @test Trixi.swap!(c, 1, 1) == MyContainer([1, 2]) # no-op

        c = MyContainer([1, 2])
        @test Trixi.swap!(c, 1, 2) == MyContainer([2, 1])
    end

    @testset "erase!" begin
        c = MyContainer([1, 2])
        @test Trixi.erase!(c, 2, 1) == MyContainer([1, 2]) # no-op

        c = MyContainer([1, 2])
        @test Trixi.erase!(c, 1) == MyContainer([0, 2])
    end

    @testset "remove_shift!" begin
        c = MyContainer([1, 2, 3, 4])
        @test Trixi.remove_shift!(c, 2, 1) == MyContainer([1, 2, 3, 4]) # no-op

        c = MyContainer([1, 2, 3, 4])
        @test Trixi.remove_shift!(c, 2, 2) == MyContainer([1, 3, 4], 4)

        c = MyContainer([1, 2, 3, 4])
        @test Trixi.remove_shift!(c, 2) == MyContainer([1, 3, 4], 4)
    end

    @testset "remove_fill!" begin
        c = MyContainer([1, 2, 3, 4])
        @test Trixi.remove_fill!(c, 2, 1) == MyContainer([1, 2, 3, 4]) # no-op

        c = MyContainer([1, 2, 3, 4])
        @test Trixi.remove_fill!(c, 2, 2) == MyContainer([1, 4, 3], 4)
    end

    @testset "reset!" begin
        c = MyContainer([1, 2, 3])
        @test Trixi.reset!(c, 2) == MyContainer(Int[], 2)
    end
end

@timed_testset "example elixirs" begin
    @test basename(examples_dir()) == "examples"
    @test !isempty(get_examples())
    @test endswith(default_example(), "elixir_advection_basic.jl")
end

@timed_testset "HLL flux with vanishing wave speed estimates (#502)" begin
    equations = CompressibleEulerEquations1D(1.4)
    u = SVector(1.0, 0.0, 0.0)
    @test !any(isnan, flux_hll(u, u, 1, equations))
end

@timed_testset "DG L2 mortar container debug output" begin
    c2d = Trixi.L2MortarContainer2D{Float64}(1, 1, 1)
    @test isnothing(display(c2d))
    c3d = Trixi.L2MortarContainer3D{Float64}(1, 1, 1)
    @test isnothing(display(c3d))
end

@timed_testset "Printing indicators/controllers" begin
    # OBS! Constructing indicators/controllers using the parameters below doesn't make sense. It's
    # just useful to run basic tests of `show` methods.

    c = ControllerThreeLevelCombined(1, 2, 3, 10.0, 11.0, 12.0, "primary", "secondary",
                                     "cache")
    @test_nowarn show(stdout, c)

    indicator_hg = IndicatorHennemannGassner(1.0, 0.0, true, "variable", "cache")
    @test_nowarn show(stdout, indicator_hg)

    limiter_idp = SubcellLimiterIDP(true, [1], true, [1], ["variable"], 0.1,
                                    true, [(Trixi.entropy_guermond_etal, min)], "cache",
                                    1, (1.0, 1.0), 1.0)
    @test_nowarn show(stdout, limiter_idp)

    indicator_loehner = IndicatorLöhner(1.0, "variable", (; cache = nothing))
    @test_nowarn show(stdout, indicator_loehner)

    indicator_max = IndicatorMax("variable", (; cache = nothing))
    @test_nowarn show(stdout, indicator_max)
end

@timed_testset "LBM 2D constructor" begin
    # Neither Mach number nor velocity set
    @test_throws ErrorException LatticeBoltzmannEquations2D(Ma = nothing, Re = 1000)
    # Both Mach number and velocity set
    @test_throws ErrorException LatticeBoltzmannEquations2D(Ma = 0.1, Re = 1000,
                                                            u0 = 1.0)
    # Neither Reynolds number nor viscosity set
    @test_throws ErrorException LatticeBoltzmannEquations2D(Ma = 0.1, Re = nothing)
    # Both Reynolds number and viscosity set
    @test_throws ErrorException LatticeBoltzmannEquations2D(Ma = 0.1, Re = 1000,
                                                            nu = 1.0)

    # No non-dimensional values set
    @test LatticeBoltzmannEquations2D(Ma = nothing, Re = nothing, u0 = 1.0,
                                      nu = 1.0) isa
          LatticeBoltzmannEquations2D
end

@timed_testset "LBM 3D constructor" begin
    # Neither Mach number nor velocity set
    @test_throws ErrorException LatticeBoltzmannEquations3D(Ma = nothing, Re = 1000)
    # Both Mach number and velocity set
    @test_throws ErrorException LatticeBoltzmannEquations3D(Ma = 0.1, Re = 1000,
                                                            u0 = 1.0)
    # Neither Reynolds number nor viscosity set
    @test_throws ErrorException LatticeBoltzmannEquations3D(Ma = 0.1, Re = nothing)
    # Both Reynolds number and viscosity set
    @test_throws ErrorException LatticeBoltzmannEquations3D(Ma = 0.1, Re = 1000,
                                                            nu = 1.0)

    # No non-dimensional values set
    @test LatticeBoltzmannEquations3D(Ma = nothing, Re = nothing, u0 = 1.0,
                                      nu = 1.0) isa
          LatticeBoltzmannEquations3D
end

@timed_testset "LBM 2D functions" begin
    # Set up LBM struct and dummy distribution
    equation = LatticeBoltzmannEquations2D(Ma = 0.1, Re = 1000)
    u = Trixi.equilibrium_distribution(1, 2, 3, equation)

    # Component-wise velocity
    @test isapprox(Trixi.velocity(u, 1, equation), 2)
    @test isapprox(Trixi.velocity(u, 2, equation), 3)
end

@timed_testset "LBM 3D functions" begin
    # Set up LBM struct and dummy distribution
    equation = LatticeBoltzmannEquations3D(Ma = 0.1, Re = 1000)
    u = Trixi.equilibrium_distribution(1, 2, 3, 4, equation)

    # Component-wise velocity
    @test isapprox(velocity(u, 1, equation), 2)
    @test isapprox(velocity(u, 2, equation), 3)
    @test isapprox(velocity(u, 3, equation), 4)
end

@timed_testset "LBMCollisionCallback" begin
    # Printing of LBM collision callback
    callback = LBMCollisionCallback()
    @test_nowarn show(stdout, callback)
    println()
    @test_nowarn show(stdout, "text/plain", callback)
    println()
end

@timed_testset "Acoustic perturbation 2D varnames" begin
    v_mean_global = (0.0, 0.0)
    c_mean_global = 1.0
    rho_mean_global = 1.0
    equations = AcousticPerturbationEquations2D(v_mean_global, c_mean_global,
                                                rho_mean_global)

    @test Trixi.varnames(cons2state, equations) ==
          ("v1_prime", "v2_prime", "p_prime_scaled")
    @test Trixi.varnames(cons2mean, equations) ==
          ("v1_mean", "v2_mean", "c_mean", "rho_mean")
end

@timed_testset "Euler conversion between conservative/entropy variables" begin
    rho, v1, v2, v3, p = 1.0, 0.1, 0.2, 0.3, 2.0

    let equations = CompressibleEulerEquations1D(1.4)
        cons_vars = prim2cons(SVector(rho, v1, p), equations)
        entropy_vars = cons2entropy(cons_vars, equations)
        @test cons_vars ≈ entropy2cons(entropy_vars, equations)

        # test tuple args
        cons_vars = prim2cons((rho, v1, p), equations)
        entropy_vars = cons2entropy(cons_vars, equations)
        @test cons_vars ≈ entropy2cons(entropy_vars, equations)
    end

    # Test PassiveTracerEquations
    let flow_equations = CompressibleEulerEquations1D(1.4)
        equations = PassiveTracerEquations(flow_equations, n_tracers = 2)
        xi1, xi2 = 0.4, 0.5
        cons_ref = SVector(rho, rho * v1, p / 0.4 + 0.5 * (rho * v1 * v1), rho * xi1,
                           rho * xi2)
        cons_test = prim2cons(SVector(rho, v1, p, xi1, xi2), equations)
        @test cons_test ≈ cons_ref
        prim_test = cons2prim(cons_test, equations)
        @test prim_test ≈ SVector(rho, v1, p, xi1, xi2)
        flow_entropy = cons2entropy(cons_ref, flow_equations)

        entropy_ref = SVector(flow_entropy[1] - (xi1^2 + xi2^2),
                              (flow_entropy[i] for i in 2:nvariables(flow_equations))...,
                              2 * xi1, 2 * xi2)
        entropy_test = cons2entropy(cons_test, equations)
        @test entropy_test ≈ entropy_ref

        # Also test density, pressure, density_pressure and entropy here because there is currently
        # no specific space for testing them (e.g., in the other equations)
        @test density(cons_test, equations) ≈ rho
        @test pressure(cons_test, equations) ≈ p
        @test density_pressure(cons_test, equations) ≈ rho * p
        @test entropy(cons_test, equations) ≈
              entropy(cons_ref, flow_equations) + rho * (xi1^2 + xi2^2)

        tracers_ = Trixi.tracers(cons_test, equations)
        @test tracers_ ≈ SVector(xi1, xi2)
        rho_tracers_ = Trixi.rho_tracers(cons_test, equations)
        @test rho_tracers_ ≈ SVector(rho * xi1, rho * xi2)
    end

    let equations = CompressibleEulerEquations2D(1.4)
        cons_vars = prim2cons(SVector(rho, v1, v2, p), equations)
        entropy_vars = cons2entropy(cons_vars, equations)
        @test cons_vars ≈ entropy2cons(entropy_vars, equations)

        # test tuple args
        cons_vars = prim2cons((rho, v1, v2, p), equations)
        entropy_vars = cons2entropy(cons_vars, equations)
        @test cons_vars ≈ entropy2cons(entropy_vars, equations)
    end

    let equations = CompressibleEulerEquations3D(1.4)
        cons_vars = prim2cons(SVector(rho, v1, v2, v3, p), equations)
        entropy_vars = cons2entropy(cons_vars, equations)
        @test cons_vars ≈ entropy2cons(entropy_vars, equations)

        # test tuple args
        cons_vars = prim2cons((rho, v1, v2, v3, p), equations)
        entropy_vars = cons2entropy(cons_vars, equations)
        @test cons_vars ≈ entropy2cons(entropy_vars, equations)
    end
end

@timed_testset "boundary_condition_do_nothing" begin
    rho, v1, v2, p = 1.0, 0.1, 0.2, 0.3, 2.0

    let equations = CompressibleEulerEquations2D(1.4)
        u = prim2cons(SVector(rho, v1, v2, p), equations)
        x = SVector(1.0, 2.0)
        t = 0.5
        surface_flux = flux_lax_friedrichs

        outward_direction = SVector(0.2, -0.3)
        @test flux(u, outward_direction, equations) ≈
              boundary_condition_do_nothing(u, outward_direction, x, t, surface_flux,
                                            equations)

        orientation = 2
        direction = 4
        @test flux(u, orientation, equations) ≈
              boundary_condition_do_nothing(u, orientation, direction, x, t,
                                            surface_flux, equations)
    end
end

@timed_testset "boundary_condition_do_nothing_non_conservative" begin
    rho, v1, v2, v3, p, B1, B2, B3, psi = 1.0, 0.1, 0.2, 0.3, 1.0, 0.0,
                                          40.0 / sqrt(4.0 * pi), 0.0, 0.0

    let equations = IdealGlmMhdEquations2D(1.4, initial_c_h = 1.0)
        u = prim2cons(SVector(rho, v1, v2, v3, p, B1, B2, B3, psi), equations)
        x = SVector(1.0, 2.0)
        t = 0.5
        surface_fluxes = (flux_lax_friedrichs, flux_nonconservative_powell)

        outward_direction = SVector(0.2, 0.3)

        @test all(isapprox(x, y)
                  for (x, y) in zip(ntuple(i -> surface_fluxes[i](u, u,
                                                                  outward_direction,
                                                                  equations), 2),
                                    boundary_condition_do_nothing(u, outward_direction,
                                                                  x, t, surface_fluxes,
                                                                  equations)))

        orientation = 2
        direction = 4

        @test all(isapprox(x, y)
                  for (x, y) in zip(ntuple(i -> surface_fluxes[i](u, u, orientation,
                                                                  equations), 2),
                                    boundary_condition_do_nothing(u, orientation,
                                                                  direction, x, t,
                                                                  surface_fluxes,
                                                                  equations)))
    end
end

@timed_testset "StepsizeCallback" begin
    # Ensure a proper error is thrown if used with adaptive time integration schemes
    @test_nowarn_mod trixi_include(@__MODULE__,
                                   joinpath(examples_dir(), "tree_2d_dgsem",
                                            "elixir_advection_diffusion.jl"),
                                   tspan = (0, 0.05))

    @test_throws ArgumentError solve(ode, alg; ode_default_options()...,
                                     callback = StepsizeCallback(cfl = 1.0))
end

@timed_testset "TimeSeriesCallback" begin
    # Test the 2D TreeMesh version of the callback and some warnings
    @test_nowarn_mod trixi_include(@__MODULE__,
                                   joinpath(examples_dir(), "tree_2d_dgsem",
                                            "elixir_acoustics_gaussian_source.jl"),
                                   tspan = (0, 0.05))

    point_data_1 = time_series.affect!.point_data[1]
    @test all(isapprox.(point_data_1[1:7],
                        [-2.4417734981719132e-5, -3.4296207289200194e-5,
                            0.0018130846385739788, -0.5, 0.25, 1.0, 1.0]))
    @test_throws DimensionMismatch Trixi.get_elements_by_coordinates!([1, 2],
                                                                      rand(2, 4), mesh,
                                                                      solver, nothing)
    @test_nowarn show(stdout, time_series)
    @test_throws ArgumentError TimeSeriesCallback(semi, [(1.0, 1.0)]; interval = -1)
    @test_throws ArgumentError TimeSeriesCallback(semi, [1.0 1.0 1.0; 2.0 2.0 2.0])
end

@timed_testset "resize! RelaxationIntegrators" begin
    equations = LinearScalarAdvectionEquation1D(42.0)
    solver = DGSEM(polydeg = 0, surface_flux = flux_ranocha)
    mesh = TreeMesh((0.0,), (1.0,),
                    initial_refinement_level = 2,
                    n_cells_max = 30_000)
    semi = SemidiscretizationHyperbolic(mesh, equations,
                                        initial_condition_convergence_test,
                                        solver)
    u0 = zeros(4)
    tspan = (0.0, 1.0)
    ode = semidiscretize(semi, tspan)

    ode_alg = Trixi.RelaxationRK44() # SubDiagonalAlgorithm
    integrator = Trixi.init(ode, ode_alg; dt = 1.0) # SubDiagonalRelaxationIntegrator

    resize!(integrator, 1001)
    @test length(integrator.u) == 1001
    @test length(integrator.du) == 1001
    @test length(integrator.u_tmp) == 1001
    @test length(integrator.direction) == 1001

    ode_alg = Trixi.RelaxationCKL54() # vanderHouwenAlgorithm
    integrator = Trixi.init(ode, ode_alg; dt = 1.0) # vanderHouwenRelaxationIntegrator

    resize!(integrator, 42)
    @test length(integrator.u) == 42
    @test length(integrator.du) == 42
    @test length(integrator.u_tmp) == 42
    @test length(integrator.k_prev) == 42
    @test length(integrator.direction) == 42
end

@timed_testset "Consistency check for single point flux: CEMCE" begin
    equations = CompressibleEulerMulticomponentEquations2D(gammas = (1.4, 1.4),
                                                           gas_constants = (0.4, 0.4))
    u = SVector(0.1, -0.5, 1.0, 1.0, 2.0)

    orientations = [1, 2]
    for orientation in orientations
        @test flux(u, orientation, equations) ≈
              flux_ranocha(u, u, orientation, equations)
    end
end

@timed_testset "Consistency check for HLL flux (naive): CEE" begin
    flux_hll = FluxHLL(min_max_speed_naive)

    # Set up equations and dummy conservative variables state
    equations = CompressibleEulerEquations1D(1.4)
    u = SVector(1.1, 2.34, 5.5)

    orientations = [1]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    equations = CompressibleEulerEquations2D(1.4)
    u = SVector(1.1, -0.5, 2.34, 5.5)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    equations = CompressibleEulerEquations3D(1.4)
    u = SVector(1.1, -0.5, 2.34, 2.4, 5.5)

    orientations = [1, 2, 3]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end
end

@timed_testset "Consistency check for flux_chan_etal: CEEQ" begin

    # Set up equations and dummy conservative variables state
    equations = CompressibleEulerEquationsQuasi1D(1.4)
    u = SVector(1.1, 2.34, 5.5, 2.73)

    orientations = [1]
    for orientation in orientations
        @test flux_chan_etal(u, u, orientation, equations) ≈
              flux(u, orientation, equations)
    end
end

@timed_testset "Consistency check for HLL flux (naive): LEE" begin
    flux_hll = FluxHLL(min_max_speed_naive)

    equations = LinearizedEulerEquations2D(SVector(1.0, 1.0), 1.0, 1.0)
    u = SVector(1.1, -0.5, 2.34, 5.5)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for HLL flux (naive): MHD" begin
    flux_hll = FluxHLL(min_max_speed_naive)

    equations = IdealGlmMhdEquations1D(1.4)
    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2)]

    for u in u_values
        @test flux_hll(u, u, 1, equations) ≈ flux(u, 1, equations)
    end

    equations = IdealGlmMhdEquations2D(1.4, 5.0) #= c_h =#
    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]
    orientations = [1, 2]

    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)]

    for u in u_values, orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    for u in u_values, normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end

    equations = IdealGlmMhdEquations3D(1.4, 5.0) #= c_h =#
    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]
    orientations = [1, 2, 3]

    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)]

    for u in u_values, orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    for u in u_values, normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for HLL flux with Davis wave speed estimates: CEE" begin
    flux_hll = FluxHLL(min_max_speed_davis)

    # Set up equations and dummy conservative variables state
    equations = CompressibleEulerEquations1D(1.4)
    u = SVector(1.1, 2.34, 5.5)

    orientations = [1]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    equations = CompressibleEulerEquations2D(1.4)
    u = SVector(1.1, -0.5, 2.34, 5.5)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end

    equations = CompressibleEulerEquations3D(1.4)
    u = SVector(1.1, -0.5, 2.34, 2.4, 5.5)

    orientations = [1, 2, 3]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]

    for normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for HLL flux with Davis wave speed estimates: Polytropic CEE" begin
    flux_hll = FluxHLL(min_max_speed_davis)

    gamma = 1.4
    kappa = 0.5     # Scaling factor for the pressure.
    equations = PolytropicEulerEquations2D(gamma, kappa)
    u = SVector(1.1, -0.5, 2.34)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for Winters flux: Polytropic CEE" begin
    for gamma in [1.4, 1.0, 5 / 3]
        kappa = 0.5     # Scaling factor for the pressure.
        equations = PolytropicEulerEquations2D(gamma, kappa)
        u = SVector(1.1, -0.5, 2.34)

        orientations = [1, 2]
        for orientation in orientations
            @test flux_winters_etal(u, u, orientation, equations) ≈
                  flux(u, orientation, equations)
        end

        normal_directions = [SVector(1.0, 0.0),
            SVector(0.0, 1.0),
            SVector(0.5, -0.5),
            SVector(-1.2, 0.3)]

        for normal_direction in normal_directions
            @test flux_winters_etal(u, u, normal_direction, equations) ≈
                  flux(u, normal_direction, equations)
        end
    end
end

@timed_testset "Consistency check for Lax-Friedrich flux: Polytropic CEE" begin
    for gamma in [1.4, 1.0, 5 / 3]
        kappa = 0.5     # Scaling factor for the pressure.
        equations = PolytropicEulerEquations2D(gamma, kappa)
        u = SVector(1.1, -0.5, 2.34)

        orientations = [1, 2]
        for orientation in orientations
            @test flux_lax_friedrichs(u, u, orientation, equations) ≈
                  flux(u, orientation, equations)
        end

        normal_directions = [SVector(1.0, 0.0),
            SVector(0.0, 1.0),
            SVector(0.5, -0.5),
            SVector(-1.2, 0.3)]

        for normal_direction in normal_directions
            @test flux_lax_friedrichs(u, u, normal_direction, equations) ≈
                  flux(u, normal_direction, equations)
        end
    end
end

@timed_testset "Consistency check for HLL flux with Davis wave speed estimates: LEE" begin
    flux_hll = FluxHLL(min_max_speed_davis)

    equations = LinearizedEulerEquations2D(SVector(1.0, 1.0), 1.0, 1.0)
    u = SVector(1.1, -0.5, 2.34, 5.5)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for HLL flux with Davis wave speed estimates: MHD" begin
    flux_hll = FluxHLL(min_max_speed_davis)

    equations = IdealGlmMhdEquations1D(1.4)
    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2)]

    for u in u_values
        @test flux_hll(u, u, 1, equations) ≈ flux(u, 1, equations)
    end

    equations = IdealGlmMhdEquations2D(1.4, 5.0) #= c_h =#
    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]
    orientations = [1, 2]

    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)]

    for u in u_values, orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    for u in u_values, normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end

    equations = IdealGlmMhdEquations3D(1.4, 5.0) #= c_h =#
    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]
    orientations = [1, 2, 3]

    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)]

    for u in u_values, orientation in orientations
        @test flux_hll(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    for u in u_values, normal_direction in normal_directions
        @test flux_hll(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for HLLE flux: CEE" begin
    # Set up equations and dummy conservative variables state
    equations = CompressibleEulerEquations1D(1.4)
    u = SVector(1.1, 2.34, 5.5)

    orientations = [1]
    for orientation in orientations
        @test flux_hlle(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    equations = CompressibleEulerEquations2D(1.4)
    u = SVector(1.1, -0.5, 2.34, 5.5)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_hlle(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions
        @test flux_hlle(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end

    equations = CompressibleEulerEquations3D(1.4)
    u = SVector(1.1, -0.5, 2.34, 2.4, 5.5)

    orientations = [1, 2, 3]
    for orientation in orientations
        @test flux_hlle(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]

    for normal_direction in normal_directions
        @test flux_hlle(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for HLLE flux: MHD" begin
    equations = IdealGlmMhdEquations1D(1.4)
    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2)]

    for u in u_values
        @test flux_hlle(u, u, 1, equations) ≈ flux(u, 1, equations)
        @test flux_hllc(u, u, 1, equations) ≈ flux(u, 1, equations)
    end

    equations = IdealGlmMhdEquations2D(1.4, 5.0) #= c_h =#
    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]
    orientations = [1, 2]

    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)]

    for u in u_values, orientation in orientations
        @test flux_hlle(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    for u in u_values, normal_direction in normal_directions
        @test flux_hlle(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end

    equations = IdealGlmMhdEquations3D(1.4, 5.0) #= c_h =#
    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]
    orientations = [1, 2, 3]

    u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)]

    for u in u_values, orientation in orientations
        @test flux_hlle(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    for u in u_values, normal_direction in normal_directions
        @test flux_hlle(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for HLLC flux: CEE" begin
    # Set up equations and dummy conservative variables state
    equations = CompressibleEulerEquations2D(1.4)
    u = SVector(1.1, -0.5, 2.34, 5.5)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_hllc(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions
        @test flux_hllc(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end

    # check consistency between 1D and 2D HLLC fluxes
    u_1d = SVector(1.1, -0.5, 5.5)
    u_2d = SVector(u_1d[1], u_1d[2], 0.0, u_1d[3])
    normal_1d = SVector(-0.3)
    normal_2d = SVector(normal_1d[1], 0.0)
    equations_1d = CompressibleEulerEquations1D(1.4)
    equations_2d = CompressibleEulerEquations2D(1.4)
    flux_1d = flux_hllc(u_1d, u_1d, normal_1d, equations_1d)
    flux_2d = flux_hllc(u_2d, u_2d, normal_2d, equations_2d)
    @test flux_1d ≈ flux(u_1d, normal_1d, equations_1d)
    @test flux_1d ≈ flux_2d[[1, 2, 4]]

    # test when u_ll is not the same as u_rr
    u_rr_1d = SVector(2.1, 0.3, 0.1)
    u_rr_2d = SVector(u_rr_1d[1], u_rr_1d[2], 0.0, u_rr_1d[3])
    flux_1d = flux_hllc(u_1d, u_rr_1d, normal_1d, equations_1d)
    flux_2d = flux_hllc(u_2d, u_rr_2d, normal_2d, equations_2d)
    @test flux_1d ≈ flux_2d[[1, 2, 4]]

    equations = CompressibleEulerEquations3D(1.4)
    u = SVector(1.1, -0.5, 2.34, 2.4, 5.5)

    orientations = [1, 2, 3]
    for orientation in orientations
        @test flux_hllc(u, u, orientation, equations) ≈ flux(u, orientation, equations)
    end

    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]

    for normal_direction in normal_directions
        @test flux_hllc(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@timed_testset "Consistency check for Godunov flux" begin
    # Set up equations and dummy conservative variables state
    # Burgers' Equation

    equation = InviscidBurgersEquation1D()
    u_values = [SVector(42.0), SVector(-42.0)]

    orientations = [1]
    for orientation in orientations, u in u_values
        @test flux_godunov(u, u, orientation, equation) ≈ flux(u, orientation, equation)
    end

    # Linear Advection 1D
    equation = LinearScalarAdvectionEquation1D(-4.2)
    u = SVector(3.14159)

    orientations = [1]
    for orientation in orientations
        @test flux_godunov(u, u, orientation, equation) ≈ flux(u, orientation, equation)
    end

    # Linear Advection 2D
    equation = LinearScalarAdvectionEquation2D(-4.2, 2.4)
    u = SVector(3.14159)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_godunov(u, u, orientation, equation) ≈ flux(u, orientation, equation)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions
        @test flux_godunov(u, u, normal_direction, equation) ≈
              flux(u, normal_direction, equation)
    end

    # Linear Advection 3D
    equation = LinearScalarAdvectionEquation3D(-4.2, 2.4, 1.2)
    u = SVector(3.14159)

    orientations = [1, 2, 3]
    for orientation in orientations
        @test flux_godunov(u, u, orientation, equation) ≈ flux(u, orientation, equation)
    end

    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]

    for normal_direction in normal_directions
        @test flux_godunov(u, u, normal_direction, equation) ≈
              flux(u, normal_direction, equation)
    end

    # Linearized Euler 2D
    equation = LinearizedEulerEquations2D(v_mean_global = (0.5, -0.7),
                                          c_mean_global = 1.1,
                                          rho_mean_global = 1.2)
    u_values = [SVector(1.0, 0.5, -0.7, 1.0),
        SVector(1.5, -0.2, 0.1, 5.0)]

    orientations = [1, 2]
    for orientation in orientations, u in u_values
        @test flux_godunov(u, u, orientation, equation) ≈ flux(u, orientation, equation)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions, u in u_values
        @test flux_godunov(u, u, normal_direction, equation) ≈
              flux(u, normal_direction, equation)
    end
end

@timed_testset "Consistency check for Engquist-Osher flux" begin
    # Set up equations and dummy conservative variables state
    equation = InviscidBurgersEquation1D()
    u_values = [SVector(42.0), SVector(-42.0)]

    orientations = [1]
    for orientation in orientations, u in u_values
        @test Trixi.flux_engquist_osher(u, u, orientation, equation) ≈
              flux(u, orientation, equation)
    end

    equation = LinearScalarAdvectionEquation1D(-4.2)
    u = SVector(3.14159)

    orientations = [1]
    for orientation in orientations
        @test Trixi.flux_engquist_osher(u, u, orientation, equation) ≈
              flux(u, orientation, equation)
    end
end

@testset "Consistency check for `gradient_conservative` routine" begin
    # Set up conservative variables, equations
    u = [
        0.5011914484393387,
        0.8829127712445113,
        0.43024132987932817,
        0.7560616633050348
    ]

    equations = CompressibleEulerEquations2D(1.4)

    # Define wrapper function for pressure in order to call default implementation
    function pressure_test(u, equations)
        return pressure(u, equations)
    end

    @test Trixi.gradient_conservative(pressure_test, u, equations) ≈
          Trixi.gradient_conservative(pressure, u, equations)
end

@testset "Equivalent Fluxes" begin
    # Set up equations and dummy conservative variables state
    # Burgers' Equation

    equation = InviscidBurgersEquation1D()
    u_values = [SVector(42.0), SVector(-42.0)]

    orientations = [1]
    for orientation in orientations, u in u_values
        @test flux_godunov(0.75 * u, u, orientation, equation) ≈
              Trixi.flux_engquist_osher(0.75 * u, u, orientation, equation)
    end

    # Linear Advection 1D
    equation = LinearScalarAdvectionEquation1D(-4.2)
    u = SVector(3.14159)

    orientations = [1]
    for orientation in orientations
        @test flux_godunov(0.5 * u, u, orientation, equation) ≈
              flux_lax_friedrichs(0.5 * u, u, orientation, equation)
        @test flux_godunov(2 * u, u, orientation, equation) ≈
              Trixi.flux_engquist_osher(2 * u, u, orientation, equation)
    end

    # Linear Advection 2D
    equation = LinearScalarAdvectionEquation2D(-4.2, 2.4)
    u = SVector(3.14159)

    orientations = [1, 2]
    for orientation in orientations
        @test flux_godunov(0.25 * u, u, orientation, equation) ≈
              flux_lax_friedrichs(0.25 * u, u, orientation, equation)
    end

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]

    for normal_direction in normal_directions
        @test flux_godunov(3 * u, u, normal_direction, equation) ≈
              flux_lax_friedrichs(3 * u, u, normal_direction, equation)
    end

    # Linear Advection 3D
    equation = LinearScalarAdvectionEquation3D(-4.2, 2.4, 1.2)
    u = SVector(3.14159)

    orientations = [1, 2, 3]
    for orientation in orientations
        @test flux_godunov(1.5 * u, u, orientation, equation) ≈
              flux_lax_friedrichs(1.5 * u, u, orientation, equation)
    end

    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]

    for normal_direction in normal_directions
        @test flux_godunov(1.3 * u, u, normal_direction, equation) ≈
              flux_lax_friedrichs(1.3 * u, u, normal_direction, equation)
    end
end

@timed_testset "Consistency check for LMARS flux" begin
    equations = CompressibleEulerEquations2D(1.4)
    flux_lmars = FluxLMARS(340)

    normal_directions = [SVector(1.0, 0.0),
        SVector(0.0, 1.0),
        SVector(0.5, -0.5),
        SVector(-1.2, 0.3)]
    orientations = [1, 2]
    u_values = [SVector(1.0, 0.5, -0.7, 1.0),
        SVector(1.5, -0.2, 0.1, 5.0)]

    for u in u_values, orientation in orientations
        @test flux_lmars(u, u, orientation, equations) ≈
              flux(u, orientation, equations)
    end

    for u in u_values, normal_direction in normal_directions
        @test flux_lmars(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end

    equations = CompressibleEulerEquations3D(1.4)
    normal_directions = [SVector(1.0, 0.0, 0.0),
        SVector(0.0, 1.0, 0.0),
        SVector(0.0, 0.0, 1.0),
        SVector(0.5, -0.5, 0.2),
        SVector(-1.2, 0.3, 1.4)]
    orientations = [1, 2, 3]
    u_values = [SVector(1.0, 0.5, -0.7, 0.1, 1.0),
        SVector(1.5, -0.2, 0.1, 0.2, 5.0)]

    for u in u_values, orientation in orientations
        @test flux_lmars(u, u, orientation, equations) ≈
              flux(u, orientation, equations)
    end

    for u in u_values, normal_direction in normal_directions
        @test flux_lmars(u, u, normal_direction, equations) ≈
              flux(u, normal_direction, equations)
    end
end

@testset "FluxRotated vs. direct implementation" begin
    @timed_testset "CompressibleEulerMulticomponentEquations2D" begin
        equations = CompressibleEulerMulticomponentEquations2D(gammas = (1.4, 1.4),
                                                               gas_constants = (0.4,
                                                                                0.4))
        normal_directions = [SVector(1.0, 0.0),
            SVector(0.0, 1.0),
            SVector(0.5, -0.5),
            SVector(-1.2, 0.3)]
        u_values = [SVector(0.1, -0.5, 1.0, 1.0, 2.0),
            SVector(-0.1, -0.3, 1.2, 1.3, 1.4)]

        f_std = flux
        f_rot = FluxRotated(f_std)
        println(typeof(f_std))
        println(typeof(f_rot))
        for u in u_values,
            normal_direction in normal_directions

            @test f_rot(u, normal_direction, equations) ≈
                  f_std(u, normal_direction, equations)
        end
    end

    @timed_testset "CompressibleEulerEquations2D" begin
        equations = CompressibleEulerEquations2D(1.4)
        normal_directions = [SVector(1.0, 0.0),
            SVector(0.0, 1.0),
            SVector(0.5, -0.5),
            SVector(-1.2, 0.3)]
        u_values = [SVector(1.0, 0.5, -0.7, 1.0),
            SVector(1.5, -0.2, 0.1, 5.0)]
        fluxes = [flux_central, flux_ranocha, flux_shima_etal, flux_kennedy_gruber,
            FluxLMARS(340), flux_hll, FluxHLL(min_max_speed_davis), flux_hlle,
            flux_hllc, flux_chandrashekar
        ]

        for f_std in fluxes
            f_rot = FluxRotated(f_std)
            for u_ll in u_values, u_rr in u_values,
                normal_direction in normal_directions

                @test f_rot(u_ll, u_rr, normal_direction, equations) ≈
                      f_std(u_ll, u_rr, normal_direction, equations)
            end
        end
    end

    @timed_testset "CompressibleEulerEquations3D" begin
        equations = CompressibleEulerEquations3D(1.4)
        normal_directions = [SVector(1.0, 0.0, 0.0),
            SVector(0.0, 1.0, 0.0),
            SVector(0.0, 0.0, 1.0),
            SVector(0.5, -0.5, 0.2),
            SVector(-1.2, 0.3, 1.4)]
        u_values = [SVector(1.0, 0.5, -0.7, 0.1, 1.0),
            SVector(1.5, -0.2, 0.1, 0.2, 5.0)]
        fluxes = [flux_central, flux_ranocha, flux_shima_etal, flux_kennedy_gruber,
            FluxLMARS(340), flux_hll, FluxHLL(min_max_speed_davis), flux_hlle,
            flux_hllc, flux_chandrashekar
        ]

        for f_std in fluxes
            f_rot = FluxRotated(f_std)
            for u_ll in u_values, u_rr in u_values,
                normal_direction in normal_directions

                @test f_rot(u_ll, u_rr, normal_direction, equations) ≈
                      f_std(u_ll, u_rr, normal_direction, equations)
            end
        end
    end

    @timed_testset "IdealGlmMhdEquations2D" begin
        equations = IdealGlmMhdEquations2D(1.4, 5.0) #= c_h =#
        normal_directions = [SVector(1.0, 0.0),
            SVector(0.0, 1.0),
            SVector(0.5, -0.5),
            SVector(-1.2, 0.3)]
        u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0),
            SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)]
        fluxes = [
            flux_central,
            flux_hindenlang_gassner,
            FluxHLL(min_max_speed_davis),
            flux_hlle
        ]

        for f_std in fluxes
            f_rot = FluxRotated(f_std)
            for u_ll in u_values, u_rr in u_values,
                normal_direction in normal_directions

                @test f_rot(u_ll, u_rr, normal_direction, equations) ≈
                      f_std(u_ll, u_rr, normal_direction, equations)
            end
        end
    end

    @timed_testset "IdealGlmMhdEquations3D" begin
        equations = IdealGlmMhdEquations3D(1.4, 5.0) #= c_h =#
        normal_directions = [SVector(1.0, 0.0, 0.0),
            SVector(0.0, 1.0, 0.0),
            SVector(0.0, 0.0, 1.0),
            SVector(0.5, -0.5, 0.2),
            SVector(-1.2, 0.3, 1.4)]
        u_values = [SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0),
            SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)]
        fluxes = [
            flux_central,
            flux_hindenlang_gassner,
            FluxHLL(min_max_speed_davis),
            flux_hlle
        ]

        for f_std in fluxes
            f_rot = FluxRotated(f_std)
            for u_ll in u_values, u_rr in u_values,
                normal_direction in normal_directions

                @test f_rot(u_ll, u_rr, normal_direction, equations) ≈
                      f_std(u_ll, u_rr, normal_direction, equations)
            end
        end
    end
end

@timed_testset "DissipationMatrixWintersEtal entropy dissipation and consistency tests" begin
    equations = CompressibleEulerEquations1D(1.4)
    dissipation_matrix_winters_etal = DissipationMatrixWintersEtal()

    # test constant preservation and entropy dissipation vector
    u_ll = prim2cons(SVector(1, 0, 2.0), equations)
    u_rr = prim2cons(SVector(1.1, 0, 2.0), equations)
    v_ll = cons2entropy(u_ll, equations)
    v_rr = cons2entropy(u_rr, equations)
    @test norm(dissipation_matrix_winters_etal(u_ll, u_rr, SVector(1.0), equations)) <
          100 * eps()
    @test dot(v_ll - v_rr,
              dissipation_matrix_winters_etal(u_ll, u_rr, SVector(1.0), equations)) ≥ 0

    # test non-unit vector
    u_ll = prim2cons(SVector(rand(), randn(), rand()), equations)
    u_rr = prim2cons(SVector(rand(), randn(), rand()), equations)
    v_ll = cons2entropy(u_ll, equations)
    v_rr = cons2entropy(u_rr, equations)
    @test dot(v_ll - v_rr,
              dissipation_matrix_winters_etal(u_ll, u_rr, SVector(1.0), equations)) ≥ 0
    @test dissipation_matrix_winters_etal(u_ll, u_rr, SVector(0.1), equations) ≈
          0.1 * dissipation_matrix_winters_etal(u_ll, u_rr, SVector(1.0), equations)

    equations = CompressibleEulerEquations2D(1.4)

    # test that 2D flux is consistent with 1D matrix flux
    u_ll = prim2cons(SVector(1, 0.1, 0, 1.0), equations)
    u_rr = prim2cons(SVector(1.1, -0.2, 0, 2.0), equations)
    v_ll = cons2entropy(u_ll, equations)
    v_rr = cons2entropy(u_rr, equations)
    normal = SVector(1.0, 0.0)
    ids = [1, 2, 4] # indices of 1D variables/fluxes within the 2D solution
    @test dissipation_matrix_winters_etal(u_ll, u_rr, normal, equations)[ids] ≈
          dissipation_matrix_winters_etal(u_ll[ids], u_rr[ids],
                                          SVector(1.0),
                                          CompressibleEulerEquations1D(1.4))

    # test 2D entropy dissipation
    u_ll = prim2cons(SVector(1, 1, -3, 100.0), equations)
    u_rr = prim2cons(SVector(100, -2, 4, 1.0), equations)
    v_ll = cons2entropy(u_ll, equations)
    v_rr = cons2entropy(u_rr, equations)
    dissipation = dissipation_matrix_winters_etal(u_ll, u_rr, SVector(1.0, 1.0),
                                                  equations)
    @test dot(v_ll - v_rr, dissipation) ≥ 0

    # test non-unit vector
    normal_direction = SVector(1.0, 2.0)
    @test dissipation_matrix_winters_etal(u_ll, u_rr, normal_direction, equations) ≈
          norm(normal_direction) * dissipation_matrix_winters_etal(u_ll, u_rr,
                                          normal_direction / norm(normal_direction),
                                          equations)

    # test that 3D flux is consistent with 1D and 2D versions
    equations = CompressibleEulerEquations3D(1.4)
    dissipation_matrix_winters_etal = DissipationMatrixWintersEtal()

    # test for consistency with 1D and 2D flux
    u_ll = prim2cons(SVector(1, 0.1, 0, 0, 1.0), equations)
    u_rr = prim2cons(SVector(1.1, -0.2, 0, 0, 2.0), equations)
    v_ll = cons2entropy(u_ll, equations)
    v_rr = cons2entropy(u_rr, equations)
    dissipation_3d = dissipation_matrix_winters_etal(u_ll, u_rr, SVector(1.0, 0.0, 0.0),
                                                     equations)
    dissipation_1d = dissipation_matrix_winters_etal(u_ll[[1, 2, 5]], u_rr[[1, 2, 5]],
                                                     SVector(1.0),
                                                     CompressibleEulerEquations1D(1.4))
    @test dissipation_3d[[1, 2, 5]] ≈ dissipation_1d

    u_ll = prim2cons(SVector(1, 0.1, 0.2, 0, 1.0), equations)
    u_rr = prim2cons(SVector(1.1, -0.2, -0.3, 0, 2.0), equations)
    v_ll = cons2entropy(u_ll, equations)
    v_rr = cons2entropy(u_rr, equations)
    dissipation_3d = dissipation_matrix_winters_etal(u_ll, u_rr, SVector(1.0, 1.0, 0.0),
                                                     equations)
    dissipation_2d = dissipation_matrix_winters_etal(u_ll[[1, 2, 3, 5]],
                                                     u_rr[[1, 2, 3, 5]],
                                                     SVector(1.0, 1.0),
                                                     CompressibleEulerEquations2D(1.4))
    @test dissipation_3d[[1, 2, 3, 5]] ≈ dissipation_2d

    # test 3D entropy dissipation
    u_ll = prim2cons(SVector(1, 0.1, 0.2, 0.3, 1.0), equations)
    u_rr = prim2cons(SVector(1.1, -0.2, -0.3, 0.4, 2.0), equations)
    v_ll = cons2entropy(u_ll, equations)
    v_rr = cons2entropy(u_rr, equations)
    dissipation_3d = dissipation_matrix_winters_etal(u_ll, u_rr, SVector(1.0, 2.0, 3.0),
                                                     equations)
    @test dot(v_ll - v_rr, dissipation_3d) ≥ 0

    # test non-unit vector
    normal_direction = SVector(1.0, 2.0, 3.0)
    @test dissipation_matrix_winters_etal(u_ll, u_rr, normal_direction, equations) ≈
          norm(normal_direction) * dissipation_matrix_winters_etal(u_ll, u_rr,
                                          normal_direction / norm(normal_direction),
                                          equations)
end

@testset "Equivalent Wave Speed Estimates" begin
    @timed_testset "Linearized Euler 3D" begin
        equations = LinearizedEulerEquations3D(v_mean_global = (0.42, 0.37, 0.7),
                                               c_mean_global = 1.0,
                                               rho_mean_global = 1.0)

        normal_x = SVector(1.0, 0.0, 0.0)
        normal_y = SVector(0.0, 1.0, 0.0)
        normal_z = SVector(0.0, 0.0, 1.0)

        u_ll = SVector(0.3, 0.5, -0.7, 0.1, 1.0)
        u_rr = SVector(0.5, -0.2, 0.1, 0.2, 5.0)

        @test all(isapprox(x, y)
                  for (x, y) in zip(max_abs_speed_naive(u_ll, u_rr, 1, equations),
                                    max_abs_speed_naive(u_ll, u_rr, normal_x,
                                                        equations)))
        @test all(isapprox(x, y)
                  for (x, y) in zip(max_abs_speed_naive(u_ll, u_rr, 2, equations),
                                    max_abs_speed_naive(u_ll, u_rr, normal_y,
                                                        equations)))
        @test all(isapprox(x, y)
                  for (x, y) in zip(max_abs_speed_naive(u_ll, u_rr, 3, equations),
                                    max_abs_speed_naive(u_ll, u_rr, normal_z,
                                                        equations)))

        @test all(isapprox(x, y)
                  for (x, y) in zip(min_max_speed_naive(u_ll, u_rr, 1, equations),
                                    min_max_speed_naive(u_ll, u_rr, normal_x,
                                                        equations)))
        @test all(isapprox(x, y)
                  for (x, y) in zip(min_max_speed_naive(u_ll, u_rr, 2, equations),
                                    min_max_speed_naive(u_ll, u_rr, normal_y,
                                                        equations)))
        @test all(isapprox(x, y)
                  for (x, y) in zip(min_max_speed_naive(u_ll, u_rr, 3, equations),
                                    min_max_speed_naive(u_ll, u_rr, normal_z,
                                                        equations)))

        @test all(isapprox(x, y)
                  for (x, y) in zip(min_max_speed_davis(u_ll, u_rr, 1, equations),
                                    min_max_speed_davis(u_ll, u_rr, normal_x,
                                                        equations)))
        @test all(isapprox(x, y)
                  for (x, y) in zip(min_max_speed_davis(u_ll, u_rr, 2, equations),
                                    min_max_speed_davis(u_ll, u_rr, normal_y,
                                                        equations)))
        @test all(isapprox(x, y)
                  for (x, y) in zip(min_max_speed_davis(u_ll, u_rr, 3, equations),
                                    min_max_speed_davis(u_ll, u_rr, normal_z,
                                                        equations)))
    end

    @timed_testset "Maxwell 1D" begin
        equations = MaxwellEquations1D()

        u_values_left = [SVector(1.0, 0.0),
            SVector(0.0, 1.0),
            SVector(0.5, -0.5),
            SVector(-1.2, 0.3)]

        u_values_right = [SVector(1.0, 0.0),
            SVector(0.0, 1.0),
            SVector(0.5, -0.5),
            SVector(-1.2, 0.3)]
        for u_ll in u_values_left, u_rr in u_values_right
            @test all(isapprox(x, y)
                      for (x, y) in zip(min_max_speed_naive(u_ll, u_rr, 1, equations),
                                        min_max_speed_davis(u_ll, u_rr, 1, equations)))
        end
    end
end

@testset "Equivalent Wave Speed Estimates: max_abs_speed(naive)" begin
    @timed_testset "AcousticPerturbationEquations2D" begin
        equations = AcousticPerturbationEquations2D(v_mean_global = (0.5, 0.3),
                                                    c_mean_global = 2.0,
                                                    rho_mean_global = 0.9)

        v1_prime_ll_rr = SVector(0.1, 0.2)
        v2_prime_ll_rr = SVector(0.3, 0.4)
        p_prime_scaled_ll_rr = SVector(0.5, 0.6)
        v1_mean_ll_rr = SVector(-0.2, -0.1)
        v2_mean_ll_rr = SVector(-0.9, -1.2)
        c_mean = 2.0 # Same for both to get same wave speed estimates
        rho_mean_ll_rr = SVector(1.3, 1.4)

        u_ll = SVector(v1_prime_ll_rr[1], v2_prime_ll_rr[1], p_prime_scaled_ll_rr[1],
                       v1_mean_ll_rr[1], v2_mean_ll_rr[1], c_mean, rho_mean_ll_rr[1])

        u_rr = SVector(v1_prime_ll_rr[2], v2_prime_ll_rr[2], p_prime_scaled_ll_rr[2],
                       v1_mean_ll_rr[2], v2_mean_ll_rr[2], c_mean, rho_mean_ll_rr[2])

        for orientation in [1, 2]
            @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                  max_abs_speed(u_ll, u_rr, orientation, equations)
        end

        normal_directions = [SVector(1.0, 0.0, 0.0),
            SVector(0.0, 1.0, 0.0),
            SVector(0.0, 0.0, 1.0),
            SVector(0.5, -0.5, 0.2),
            SVector(-1.2, 0.3, 1.4)]

        for normal_direction in normal_directions
            @test max_abs_speed_naive(u_ll, u_rr, normal_direction, equations) ≈
                  max_abs_speed(u_ll, u_rr, normal_direction, equations)
        end
    end

    @timed_testset "CompressibleEulerEquations1D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = CompressibleEulerEquations1D(gamma)

            p_rho_ratio = 42.0

            rho_ll_rr = SVector(2.0, 1.0)
            v_ll_rr = SVector(0.1, 0.2)
            p_ll_rr = SVector(p_rho_ratio * rho_ll_rr[1], p_rho_ratio * rho_ll_rr[2])

            u_ll = prim2cons(SVector(rho_ll_rr[1], v_ll_rr[1], p_ll_rr[1]), equations)
            u_rr = prim2cons(SVector(rho_ll_rr[2], v_ll_rr[2], p_ll_rr[2]), equations)

            @test max_abs_speed_naive(u_ll, u_rr, 1, equations) ≈
                  max_abs_speed(u_ll, u_rr, 1, equations)
        end
    end

    @timed_testset "Passive tracer equations" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            flow_equations = CompressibleEulerEquations1D(gamma)
            equations = PassiveTracerEquations(flow_equations, n_tracers = 2)

            p_rho_ratio = 42.0
            xi1_ll, xi1_rr = 0.1, 0.2
            xi2_ll, xi2_rr = 0.3, 0.4

            rho_ll_rr = SVector(2.0, 1.0)
            v_ll_rr = SVector(0.1, 0.2)
            p_ll_rr = SVector(p_rho_ratio * rho_ll_rr[1], p_rho_ratio * rho_ll_rr[2])

            u_ll = prim2cons(SVector(rho_ll_rr[1], v_ll_rr[1], p_ll_rr[1], xi1_ll,
                                     xi2_ll), equations)
            u_rr = prim2cons(SVector(rho_ll_rr[2], v_ll_rr[2], p_ll_rr[2], xi1_rr,
                                     xi2_rr), equations)

            @test max_abs_speed_naive(u_ll, u_rr, 1, equations) ≈
                  max_abs_speed_naive(u_ll, u_rr, 1, flow_equations)
        end
    end

    @timed_testset "CompressibleEulerEquations2D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = CompressibleEulerEquations2D(gamma)

            p_rho_ratio = 27.0

            rho_ll_rr = SVector(2.0, 1.0)
            v1_ll_rr = SVector(0.1, 0.2)
            v2_ll_rr = SVector(0.4, 0.3)
            p_ll_rr = SVector(p_rho_ratio * rho_ll_rr[1], p_rho_ratio * rho_ll_rr[2])

            u_ll = prim2cons(SVector(rho_ll_rr[1], v1_ll_rr[1], v2_ll_rr[1],
                                     p_ll_rr[1]), equations)
            u_rr = prim2cons(SVector(rho_ll_rr[2], v1_ll_rr[2], v2_ll_rr[2],
                                     p_ll_rr[2]), equations)

            for orientation in [1, 2]
                @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                      max_abs_speed(u_ll, u_rr, orientation, equations)
            end

            normal_directions = [SVector(1.0, 0.0),
                SVector(0.0, 1.0),
                SVector(0.5, -0.5),
                SVector(-1.2, 0.3)]

            for normal_direction in normal_directions
                @test max_abs_speed_naive(u_ll, u_rr, normal_direction, equations) ≈
                      max_abs_speed(u_ll, u_rr, normal_direction, equations)
            end
        end
    end

    @timed_testset "CompressibleEulerEquations3D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = CompressibleEulerEquations3D(gamma)

            p_rho_ratio = 11.0

            rho_ll_rr = SVector(1.0, 2.0)
            v1_ll_rr = SVector(0.1, 0.2)
            v2_ll_rr = SVector(0.4, 0.3)
            v3_ll_rr = SVector(0.9, 0.8)
            p_ll_rr = SVector(p_rho_ratio * rho_ll_rr[1], p_rho_ratio * rho_ll_rr[2])

            u_ll = prim2cons(SVector(rho_ll_rr[1],
                                     v1_ll_rr[1], v2_ll_rr[1], v3_ll_rr[1],
                                     p_ll_rr[1]), equations)
            u_rr = prim2cons(SVector(rho_ll_rr[2],
                                     v1_ll_rr[2], v2_ll_rr[2], v3_ll_rr[2],
                                     p_ll_rr[2]), equations)

            for orientation in [1, 2, 3]
                @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                      max_abs_speed(u_ll, u_rr, orientation, equations)
            end

            normal_directions = [SVector(1.0, 0.0, 0.0),
                SVector(0.0, 1.0, 0.0),
                SVector(0.0, 0.0, 1.0),
                SVector(0.5, -0.5, 0.2),
                SVector(-1.2, 0.3, 1.4)]

            for normal_direction in normal_directions
                @test max_abs_speed_naive(u_ll, u_rr, normal_direction, equations) ≈
                      max_abs_speed(u_ll, u_rr, normal_direction, equations)
            end
        end
    end

    @timed_testset "CompressibleEulerMulticomponentEquations1D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = CompressibleEulerMulticomponentEquations1D(gammas = (gamma,
                                                                             gamma),
                                                                   gas_constants = (0.5,
                                                                                    0.4))

            p_rho_ratio = 42.0

            rho1_ll_rr = SVector(2.0, 1.0)
            rho2_ll_rr = SVector(2.0, 1.0)
            v_ll_rr = SVector(0.1, 0.2)
            p_ll_rr = SVector(p_rho_ratio * rho1_ll_rr[1], p_rho_ratio * rho1_ll_rr[2])

            u_ll = prim2cons(SVector(v_ll_rr[1], p_ll_rr[1], rho1_ll_rr[1],
                                     rho2_ll_rr[1]), equations)
            u_rr = prim2cons(SVector(v_ll_rr[2], p_ll_rr[2], rho1_ll_rr[2],
                                     rho2_ll_rr[2]), equations)

            @test max_abs_speed_naive(u_ll, u_rr, 1, equations) ≈
                  max_abs_speed(u_ll, u_rr, 1, equations)
        end
    end

    @timed_testset "CompressibleEulerMulticomponentEquations2D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = CompressibleEulerMulticomponentEquations2D(gammas = (gamma,
                                                                             gamma),
                                                                   gas_constants = (0.5,
                                                                                    0.6))

            p_rho_ratio = 27.0

            rho1_ll_rr = SVector(2.0, 1.0)
            rho2_ll_rr = SVector(2.0, 1.0)
            v1_ll_rr = SVector(0.1, 0.2)
            v2_ll_rr = SVector(0.4, 0.3)
            p_ll_rr = SVector(p_rho_ratio * rho1_ll_rr[1], p_rho_ratio * rho1_ll_rr[2])

            u_ll = prim2cons(SVector(v1_ll_rr[1], v2_ll_rr[1], p_ll_rr[1],
                                     rho1_ll_rr[1], rho2_ll_rr[1]), equations)
            u_rr = prim2cons(SVector(v1_ll_rr[2], v2_ll_rr[2], p_ll_rr[2],
                                     rho1_ll_rr[2], rho2_ll_rr[2]), equations)

            for orientation in [1, 2]
                @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                      max_abs_speed(u_ll, u_rr, orientation, equations)
            end
        end
    end

    @timed_testset "CompressibleEulerEquationsQuasi1D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = CompressibleEulerEquationsQuasi1D(gamma)

            p_rho_ratio = 11.0

            rho_ll_rr = SVector(1.0, 2.0)
            v_ll_rr = SVector(0.1, 0.2)
            a_ll_rr = SVector(0.3, 0.4)
            p_ll_rr = SVector(p_rho_ratio * rho_ll_rr[1], p_rho_ratio * rho_ll_rr[2])

            u_ll = prim2cons(SVector(rho_ll_rr[1], v_ll_rr[1], p_ll_rr[1], a_ll_rr[1]),
                             equations)
            u_rr = prim2cons(SVector(rho_ll_rr[2], v_ll_rr[2], p_ll_rr[2], a_ll_rr[2]),
                             equations)

            @test max_abs_speed_naive(u_ll, u_rr, 1, equations) ≈
                  max_abs_speed(u_ll, u_rr, 1, equations)

            @test u_ll ≈ entropy2cons(cons2entropy(u_ll, equations), equations)
        end
    end

    @timed_testset "IdealGlmMhdEquations1D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = IdealGlmMhdEquations1D(gamma)

            rho = 42.0
            v1_ll_rr = SVector(0.1, 0.2)
            v2_ll_rr = SVector(0.2, 0.1)
            v3 = 0.0
            p = 0.4
            B1 = 1.01
            B2 = -0.3
            B3 = 0.5

            u_ll = prim2cons(SVector(rho, v1_ll_rr[1], v2_ll_rr[1], v3, p, B1, B2, B3),
                             equations)

            u_rr = prim2cons(SVector(rho, v1_ll_rr[2], v2_ll_rr[2], v3, p, B1, B2, B3),
                             equations)

            @test max_abs_speed_naive(u_ll, u_rr, 1, equations) ≈
                  max_abs_speed(u_ll, u_rr, 1, equations)
        end
    end

    @timed_testset "IdealGlmMhdEquations2D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = IdealGlmMhdEquations2D(gamma)

            rho = 42.0
            v1_ll_rr = SVector(0.1, 0.2)
            v2_ll_rr = SVector(0.2, 0.1)
            v3 = 0.0
            p = 0.4
            B1 = 1.01
            B2 = -0.3
            B3 = 0.5
            psi = 0.1

            u_ll = prim2cons(SVector(rho, v1_ll_rr[1], v2_ll_rr[1], v3, p, B1, B2, B3,
                                     psi), equations)

            u_rr = prim2cons(SVector(rho, v1_ll_rr[2], v2_ll_rr[2], v3, p, B1, B2, B3,
                                     psi), equations)

            for orientation in [1, 2]
                @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                      max_abs_speed(u_ll, u_rr, orientation, equations)
            end

            normal_directions = [SVector(1.0, 0.0),
                SVector(0.0, 1.0),
                SVector(0.5, -0.5),
                SVector(-1.2, 0.3)]

            for normal_direction in normal_directions
                @test max_abs_speed_naive(u_ll, u_rr, normal_direction, equations) ≈
                      max_abs_speed(u_ll, u_rr, normal_direction, equations)
            end
        end
    end

    @timed_testset "IdealGlmMhdEquations3D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = IdealGlmMhdEquations3D(gamma)

            rho = 42.0
            v1 = 0.0
            v2_ll_rr = SVector(0.2, 0.1)
            v3_ll_rr = SVector(0.1, 0.2)
            p = 0.4
            B1 = 1.01
            B2 = -0.3
            B3 = 0.5
            psi = 0.1

            u_ll = prim2cons(SVector(rho, v1, v2_ll_rr[1], v3_ll_rr[1], p, B1, B2, B3,
                                     psi), equations)

            u_rr = prim2cons(SVector(rho, v1, v2_ll_rr[2], v3_ll_rr[2], p, B1, B2, B3,
                                     psi), equations)

            for orientation in [1, 2, 3]
                @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                      max_abs_speed(u_ll, u_rr, orientation, equations)
            end

            normal_directions = [SVector(1.0, 0.0, 0.0),
                SVector(0.0, 1.0, 0.0),
                SVector(0.0, 0.0, 1.0),
                SVector(0.5, -0.5, 0.2),
                SVector(-1.2, 0.3, 1.4)]

            for normal_direction in normal_directions
                @test max_abs_speed_naive(u_ll, u_rr, normal_direction, equations) ≈
                      max_abs_speed(u_ll, u_rr, normal_direction, equations)
            end
        end
    end

    @timed_testset "IdealGlmMhdMulticomponentEquations1D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = IdealGlmMhdMulticomponentEquations1D(gammas = (gamma,
                                                                       gamma),
                                                             gas_constants = (0.5,
                                                                              0.4))

            rho1_ll_rr = SVector(2.0, 1.0)
            rho2_ll_rr = SVector(2.0, 1.0)
            v1_ll_rr = SVector(0.1, 0.2)
            v2_ll_rr = SVector(0.2, 0.1)
            v3 = 0.0
            p = 0.4
            B1 = 1.01
            B2 = -0.3
            B3 = 0.5

            u_ll = prim2cons(SVector(v1_ll_rr[1], v2_ll_rr[1], v3, p, B1, B2, B3,
                                     rho1_ll_rr[1], rho2_ll_rr[1]), equations)
            u_rr = prim2cons(SVector(v1_ll_rr[2], v2_ll_rr[2], v3, p, B1, B2, B3,
                                     rho1_ll_rr[2], rho2_ll_rr[2]), equations)

            @test max_abs_speed_naive(u_ll, u_rr, 1, equations) ≈
                  max_abs_speed(u_ll, u_rr, 1, equations)
        end
    end

    @timed_testset "IdealGlmMhdMulticomponentEquations2D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = IdealGlmMhdMulticomponentEquations2D(gammas = (gamma,
                                                                       gamma),
                                                             gas_constants = (0.5,
                                                                              0.4))

            rho1_ll_rr = SVector(0.5, 0.5)
            rho2_ll_rr = SVector(0.5, 0.5)
            v1_ll_rr = SVector(0.1, 0.2)
            v2_ll_rr = SVector(0.2, 0.1)
            v3 = 0.0
            p = 0.4
            B1 = 1.1
            B2 = -0.3
            B3 = 0.4
            psi = 0.1

            u_ll = prim2cons(SVector(v1_ll_rr[1], v2_ll_rr[1], v3, p, B1, B2, B3, psi,
                                     rho1_ll_rr[1], rho2_ll_rr[1]), equations)
            u_rr = prim2cons(SVector(v1_ll_rr[2], v2_ll_rr[2], v3, p, B1, B2, B3, psi,
                                     rho1_ll_rr[2], rho2_ll_rr[2]), equations)

            for orientation in [1, 2]
                @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                      max_abs_speed(u_ll, u_rr, orientation, equations)
            end
        end
    end

    @timed_testset "IdealGlmMhdMultiIonEquations2D" begin
        equations = IdealGlmMhdMultiIonEquations2D(gammas = (1.4, 1.667),
                                                   charge_to_mass = (1.0, 2.0))

        B1 = 1.1
        B2 = -0.3
        B3 = 0.4
        rho1_ll_rr = SVector(0.5, 0.5)
        rho2_ll_rr = SVector(0.5, 0.5)
        vx1_ll_rr = SVector(0.1, 0.1)
        vx2_ll_rr = SVector(0.2, 0.2)
        vy1_ll_rr = SVector(0.3, 0.3)
        vy2_ll_rr = SVector(0.4, 0.4)
        vz1 = 0.0
        vz2 = 0.0
        p1 = 0.4
        p2 = 0.4
        psi = 0.1

        u_ll = prim2cons(SVector(B1, B2, B3, rho1_ll_rr[1], rho2_ll_rr[1],
                                 vx1_ll_rr[1], vy1_ll_rr[1], vx2_ll_rr[1], vy2_ll_rr[1],
                                 vz1, vz2, p1, p2, psi), equations)

        u_rr = prim2cons(SVector(B1, B2, B3, rho1_ll_rr[2], rho2_ll_rr[2],
                                 vx1_ll_rr[2], vy1_ll_rr[2], vx2_ll_rr[2], vy2_ll_rr[2],
                                 vz1, vz2, p1, p2, psi), equations)

        for orientation in [1, 2]
            @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                  max_abs_speed(u_ll, u_rr, orientation, equations)
        end
    end

    @timed_testset "IdealGlmMhdMultiIonEquations3D" begin
        equations = IdealGlmMhdMultiIonEquations3D(gammas = (1.4, 1.667),
                                                   charge_to_mass = (1.0, 2.0))

        B1 = 1.1
        B2 = -0.3
        B3 = 0.4
        rho1_ll_rr = SVector(0.5, 0.5)
        rho2_ll_rr = SVector(0.5, 0.5)
        vx1_ll_rr = SVector(0.1, 0.1)
        vx2_ll_rr = SVector(0.2, 0.2)
        vy1_ll_rr = SVector(0.3, 0.3)
        vy2_ll_rr = SVector(0.4, 0.4)
        vz1_ll_rr = SVector(0.5, 0.5)
        vz2_ll_rr = SVector(0.6, 0.6)
        p1 = 0.4
        p2 = 0.4
        psi = 0.1

        u_ll = prim2cons(SVector(B1, B2, B3, rho1_ll_rr[1], rho2_ll_rr[1],
                                 vx1_ll_rr[1], vy1_ll_rr[1], vx2_ll_rr[1], vy2_ll_rr[1],
                                 vz1_ll_rr[1], vz2_ll_rr[1], p1, p2, psi), equations)

        u_rr = prim2cons(SVector(B1, B2, B3, rho1_ll_rr[2], rho2_ll_rr[2],
                                 vx1_ll_rr[2], vy1_ll_rr[2], vx2_ll_rr[2], vy2_ll_rr[2],
                                 vz1_ll_rr[2], vz2_ll_rr[2], p1, p2, psi), equations)

        for orientation in [1, 2, 3]
            @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                  max_abs_speed(u_ll, u_rr, orientation, equations)
        end

        normal_directions = [SVector(1.0, 0.0, 0.0),
            SVector(0.0, 1.0, 0.0),
            SVector(0.0, 0.0, 1.0),
            SVector(0.5, -0.5, 0.2),
            SVector(-1.2, 0.3, 1.4)]

        for normal_direction in normal_directions
            @test max_abs_speed_naive(u_ll, u_rr, normal_direction, equations) ≈
                  max_abs_speed(u_ll, u_rr, normal_direction, equations)
        end
    end

    @timed_testset "PolytropicEulerEquations2D" begin
        for gamma in [1.4, 5 / 3, 7 / 5]
            equations = PolytropicEulerEquations2D(gamma, gamma * 0.72)

            rho_ll_rr = SVector(2.0, 2.0)
            v1_ll_rr = SVector(0.1, 0.2)
            v2_ll_rr = SVector(0.4, 0.3)

            u_ll = prim2cons(SVector(rho_ll_rr[1], v1_ll_rr[1], v2_ll_rr[1]), equations)
            u_rr = prim2cons(SVector(rho_ll_rr[2], v1_ll_rr[2], v2_ll_rr[2]), equations)

            for orientation in [1, 2]
                @test max_abs_speed_naive(u_ll, u_rr, orientation, equations) ≈
                      max_abs_speed(u_ll, u_rr, orientation, equations)
            end

            normal_directions = [SVector(1.0, 0.0),
                SVector(0.0, 1.0),
                SVector(0.5, -0.5),
                SVector(-1.2, 0.3)]

            for normal_direction in normal_directions
                @test max_abs_speed_naive(u_ll, u_rr, normal_direction, equations) ≈
                      max_abs_speed(u_ll, u_rr, normal_direction, equations)
            end
        end
    end
end

@testset "SimpleKronecker" begin
    N = 3

    NDIMS = 2
    r, s = StartUpDG.nodes(Quad(), N)
    V = StartUpDG.vandermonde(Quad(), N, r, s)
    r1D = StartUpDG.nodes(Line(), N)
    V1D = StartUpDG.vandermonde(Line(), N, r1D)

    x = r + s
    V_kron = Trixi.SimpleKronecker(NDIMS, V1D, eltype(x))

    b = similar(x)
    b_kron = similar(x)
    Trixi.mul!(b, V, x)
    Trixi.mul!(b_kron, V_kron, x)
    @test b ≈ b_kron
end

@testset "SummationByPartsOperators + StartUpDG" begin
    global D = derivative_operator(SummationByPartsOperators.MattssonNordström2004(),
                                   derivative_order = 1,
                                   accuracy_order = 4,
                                   xmin = 0.0, xmax = 1.0,
                                   N = 10)
    dg = DGMulti(polydeg = 3, element_type = Quad(), approximation_type = D)

    @test StartUpDG.inverse_trace_constant(dg.basis) ≈ 50.8235294117647
end

@testset "1D non-periodic DGMultiMesh" begin
    # checks whether or not boundary faces are initialized correctly for DGMultiMesh in 1D
    dg = DGMulti(polydeg = 1, element_type = Line(), approximation_type = Polynomial(),
                 surface_integral = SurfaceIntegralWeakForm(flux_central),
                 volume_integral = VolumeIntegralFluxDifferencing(flux_central))
    cells_per_dimension = (1,)
    mesh = DGMultiMesh(dg, cells_per_dimension, periodicity = false)

    @test mesh.boundary_faces[:entire_boundary] == [1, 2]
end

@testset "PERK Single p2 Constructors" begin
    path_coeff_file = mktempdir()
    Trixi.download("https://gist.githubusercontent.com/DanielDoehring/8db0808b6f80e59420c8632c0d8e2901/raw/39aacf3c737cd642636dd78592dbdfe4cb9499af/MonCoeffsS6p2.txt",
                   joinpath(path_coeff_file, "gamma_6.txt"))

    ode_algorithm = Trixi.PairedExplicitRK2(6, path_coeff_file)

    @test isapprox(transpose(ode_algorithm.a_matrix),
                   [0.12405417889682908 0.07594582110317093
                    0.16178873711001726 0.13821126288998273
                    0.16692313960864164 0.2330768603913584
                    0.12281292901258256 0.37718707098741744], atol = 1e-13)

    Trixi.download("https://gist.githubusercontent.com/DanielDoehring/c7a89eaaa857e87dde055f78eae9b94a/raw/2937f8872ffdc08e0dcf444ee35f9ebfe18735b0/Spectrum_2D_IsentropicVortex_CEE.txt",
                   joinpath(path_coeff_file, "spectrum_2d.txt"))

    eig_vals = readdlm(joinpath(path_coeff_file, "spectrum_2d.txt"), ComplexF64)
    tspan = (0.0, 1.0)
    ode_algorithm = Trixi.PairedExplicitRK2(12, tspan, vec(eig_vals))

    @test isapprox(transpose(ode_algorithm.a_matrix),
                   [0.06453812656711647 0.02637096434197444
                    0.09470601372274887 0.041657622640887494
                    0.12332877820069793 0.058489403617483886
                    0.14987015032771522 0.07740257694501203
                    0.1734211495362651 0.0993061231910076
                    0.19261978147948638 0.1255620367023318
                    0.20523340226247055 0.1584029613738931
                    0.20734890429023528 0.20174200480067384
                    0.1913514234997008 0.26319403104575373
                    0.13942836392866081 0.3605716360713392], atol = 1e-13)
end

@testset "PERK Single p3 Constructors" begin
    path_coeff_file = mktempdir()
    Trixi.download("https://gist.githubusercontent.com/warisa-r/0796db36abcd5abe735ac7eebf41b973/raw/32889062fd5dcf7f450748f4f5f0797c8155a18d/a_8_8.txt",
                   joinpath(path_coeff_file, "a_8.txt"))

    ode_algorithm = Trixi.PairedExplicitRK3(8, path_coeff_file)

    @test isapprox(transpose(ode_algorithm.a_matrix),
                   [0.33551678438002486 0.06448322158043965
                    0.49653494442225443 0.10346507941960345
                    0.6496890912144586 0.15031092070647037
                    0.789172498521197 0.21082750147880308
                    0.7522972036571336 0.2477027963428664
                    0.31192569908571666 0.18807430091428337], atol = 1e-13)

    Trixi.download("https://gist.githubusercontent.com/warisa-r/8d93f6a3ae0635e13b9f51ee32ab7fff/raw/54dc5b14be9288e186b745facb5bbcb04d1476f8/EigenvalueList_Refined2.txt",
                   joinpath(path_coeff_file, "spectrum.txt"))

    eig_vals = readdlm(joinpath(path_coeff_file, "spectrum.txt"), ComplexF64)
    tspan = (0.0, 1.0)
    ode_algorithm = Trixi.PairedExplicitRK3(13, tspan, vec(eig_vals))

    @test isapprox(transpose(ode_algorithm.a_matrix),
                   [0.19121164778938382 0.008788355190848427
                    0.28723462747227385 0.012765384448655121
                    0.38017717196008227 0.019822834000382223
                    0.4706748928843403 0.029325107115659724
                    0.557574833668358 0.04242519017349991
                    0.6390917512034328 0.06090823687563831
                    0.7124876770174374 0.08751233490349149
                    0.7736369992226316 0.12636297693551043
                    0.8161315324169078 0.1838684675830921
                    0.7532704453316061 0.2467295546683939
                    0.31168238866709846 0.18831761133290154], atol = 1e-13)
end

@testset "PERK Single p4 Constructors" begin
    path_coeff_file = mktempdir()
    Trixi.download("https://gist.githubusercontent.com/warisa-r/8d93f6a3ae0635e13b9f51ee32ab7fff/raw/54dc5b14be9288e186b745facb5bbcb04d1476f8/EigenvalueList_Refined2.txt",
                   joinpath(path_coeff_file, "spectrum.txt"))

    eig_vals = readdlm(joinpath(path_coeff_file, "spectrum.txt"), ComplexF64)
    tspan = (0.0, 1.0)
    ode_algorithm = Trixi.PairedExplicitRK4(14, tspan, vec(eig_vals))

    @test isapprox(transpose(ode_algorithm.a_matrix),
                   [0.9935765040401348 0.0064234959598652
                    0.9849926812139576 0.0150073187860425
                    0.9731978940975923 0.0268021059024077
                    0.9564664284695985 0.0435335715304015
                    0.9319632992510594 0.0680367007489407
                    0.8955171743167522 0.1044828256832478
                    0.8443975130657495 0.1556024869342504
                    0.7922561745278265 0.2077438254721735
                    0.7722324105428290 0.2277675894571710], atol = 1e-13)
end

@testset "Sutherlands Law" begin
    function mu(u, equations)
        T_ref = 291.15

        R_specific_air = 287.052874
        T = R_specific_air * Trixi.temperature(u, equations)

        C_air = 120.0
        mu_ref_air = 1.827e-5

        return mu_ref_air * (T_ref + C_air) / (T + C_air) * (T / T_ref)^1.5
    end

    function mu_control(u, equations, T_ref, R_specific, C, mu_ref)
        T = R_specific * Trixi.temperature(u, equations)

        return mu_ref * (T_ref + C) / (T + C) * (T / T_ref)^1.5
    end

    # Dry air (values from Wikipedia: https://de.wikipedia.org/wiki/Sutherland-Modell)
    T_ref = 291.15
    C = 120.0 # Sutherland's constant
    R_specific = 287.052874
    mu_ref = 1.827e-5
    prandtl_number() = 0.72
    gamma = 1.4

    equations = CompressibleEulerEquations2D(gamma)
    equations_parabolic = CompressibleNavierStokesDiffusion2D(equations, mu = mu,
                                                              Prandtl = prandtl_number())

    # Flow at rest
    u = prim2cons(SVector(1.0, 0.0, 0.0, 1.0), equations_parabolic)

    # Comparison value from https://www.engineeringtoolbox.com/air-absolute-kinematic-viscosity-d_601.html at 18°C
    @test isapprox(mu_control(u, equations_parabolic, T_ref, R_specific, C, mu_ref),
                   1.803e-5, atol = 5e-8)
end

# Velocity functions are present in many equations and are tested here
@testset "Velocity functions for different equations" begin
    gamma = 1.4
    rho = pi * pi
    pres = sqrt(pi)
    v1, v2, v3 = pi, exp(1.0), exp(pi) # use pi, exp to test with non-trivial numbers
    v_vector = SVector(v1, v2, v3)
    normal_direction_2d = SVector(pi^2, pi^3)
    normal_direction_3d = SVector(normal_direction_2d..., pi^4)
    v_normal_1d = v1 * normal_direction_2d[1]
    v_normal_2d = v1 * normal_direction_2d[1] + v2 * normal_direction_2d[2]
    v_normal_3d = v_normal_2d + v3 * normal_direction_3d[3]

    equations_euler_1d = CompressibleEulerEquations1D(gamma)
    u = prim2cons(SVector(rho, v1, pres), equations_euler_1d)
    @test isapprox(velocity(u, equations_euler_1d), v1)
    orientation = 1 # 1D only has one orientation
    @test isapprox(velocity(u, orientation, equations_euler_1d), v1)

    equations_euler_2d = CompressibleEulerEquations2D(gamma)
    u = prim2cons(SVector(rho, v1, v2, pres), equations_euler_2d)
    @test isapprox(velocity(u, equations_euler_2d), SVector(v1, v2))
    @test isapprox(velocity(u, normal_direction_2d, equations_euler_2d), v_normal_2d)
    for orientation in 1:2
        @test isapprox(velocity(u, orientation, equations_euler_2d),
                       v_vector[orientation])
    end

    equations_euler_3d = CompressibleEulerEquations3D(gamma)
    u = prim2cons(SVector(rho, v1, v2, v3, pres), equations_euler_3d)
    @test isapprox(velocity(u, equations_euler_3d), SVector(v1, v2, v3))
    @test isapprox(velocity(u, normal_direction_3d, equations_euler_3d), v_normal_3d)
    for orientation in 1:3
        @test isapprox(velocity(u, orientation, equations_euler_3d),
                       v_vector[orientation])
    end

    rho1, rho2 = rho, rho * pi # use pi to test with non-trivial numbers
    gammas = (gamma, exp(gamma))
    gas_constants = (0.387, 1.678) # Standard numbers + 0.1

    equations_multi_euler_1d = CompressibleEulerMulticomponentEquations1D(; gammas,
                                                                          gas_constants)
    u = prim2cons(SVector(v1, pres, rho1, rho2), equations_multi_euler_1d)
    @test isapprox(velocity(u, equations_multi_euler_1d), v1)

    equations_multi_euler_2d = CompressibleEulerMulticomponentEquations2D(; gammas,
                                                                          gas_constants)
    u = prim2cons(SVector(v1, v2, pres, rho1, rho2), equations_multi_euler_2d)
    @test isapprox(velocity(u, equations_multi_euler_2d), SVector(v1, v2))
    @test isapprox(velocity(u, normal_direction_2d, equations_multi_euler_2d),
                   v_normal_2d)
    for orientation in 1:2
        @test isapprox(velocity(u, orientation, equations_multi_euler_2d),
                       v_vector[orientation])
    end

    kappa = 0.1 * pi # pi for non-trivial test
    equations_polytropic = PolytropicEulerEquations2D(gamma, kappa)
    u = prim2cons(SVector(rho, v1, v2), equations_polytropic)
    @test isapprox(velocity(u, equations_polytropic), SVector(v1, v2))
    equations_polytropic = CompressibleEulerMulticomponentEquations2D(; gammas,
                                                                      gas_constants)
    u = prim2cons(SVector(v1, v2, pres, rho1, rho2), equations_polytropic)
    @test isapprox(velocity(u, equations_polytropic), SVector(v1, v2))
    @test isapprox(velocity(u, normal_direction_2d, equations_polytropic), v_normal_2d)
    for orientation in 1:2
        @test isapprox(velocity(u, orientation, equations_polytropic),
                       v_vector[orientation])
    end

    B1, B2, B3 = pi^3, pi^4, pi^5
    equations_ideal_mhd_1d = IdealGlmMhdEquations1D(gamma)
    u = prim2cons(SVector(rho, v1, v2, v3, pres, B1, B2, B3), equations_ideal_mhd_1d)
    @test isapprox(velocity(u, equations_ideal_mhd_1d), SVector(v1, v2, v3))
    for orientation in 1:3
        @test isapprox(velocity(u, orientation, equations_ideal_mhd_1d),
                       v_vector[orientation])
    end

    psi = exp(0.1)
    equations_ideal_mhd_2d = IdealGlmMhdEquations2D(gamma)
    u = prim2cons(SVector(rho, v1, v2, v3, pres, B1, B2, B3, psi),
                  equations_ideal_mhd_2d)
    @test isapprox(velocity(u, equations_ideal_mhd_2d), SVector(v1, v2, v3))
    @test isapprox(velocity(u, normal_direction_2d, equations_ideal_mhd_2d),
                   v_normal_2d)
    for orientation in 1:3
        @test isapprox(velocity(u, orientation, equations_ideal_mhd_2d),
                       v_vector[orientation])
    end

    equations_ideal_mhd_3d = IdealGlmMhdEquations3D(gamma)
    u = prim2cons(SVector(rho, v1, v2, v3, pres, B1, B2, B3, psi),
                  equations_ideal_mhd_3d)
    @test isapprox(velocity(u, equations_ideal_mhd_3d), SVector(v1, v2, v3))
    @test isapprox(velocity(u, normal_direction_3d, equations_ideal_mhd_3d),
                   v_normal_3d)
    for orientation in 1:3
        @test isapprox(velocity(u, orientation, equations_ideal_mhd_3d),
                       v_vector[orientation])
    end
end

@testset "Pretty_form output for lake_at_rest_error" begin
    @test Trixi.pretty_form_utf(lake_at_rest_error) == "∑|H₀-(h+b)|"
    @test Trixi.pretty_form_ascii(lake_at_rest_error) == "|H0-(h+b)|"
end

# Ensure consistency for nonconservative fluxes used in the subcell-limiting. Specifically, test
# that flux_noncons_local_structured = flux_noncons_local * flux_noncons_structured.
@testset "Nonconservative fluxes for subcell-limiting" begin
    equations = IdealGlmMhdEquations2D(1.4)
    u_ll = SVector(1.0, 0.4, -0.5, 0.1, 1.0, 0.1, -0.2, 0.1, 0.0)
    u_rr = SVector(1.5, -0.2, 0.1, 0.2, 5.0, -0.1, 0.1, 0.2, 0.2)

    ## Tests for flux_nonconservative_powell_local_symmetric
    # Implementation for meshes with orientation
    for orientation in 1:2
        flux_noncons = zero(u_ll)
        for noncons in 1:Trixi.n_nonconservative_terms(flux_nonconservative_powell_local_symmetric)
            flux_noncons += flux_nonconservative_powell_local_symmetric(u_ll, 1,
                                                                        equations,
                                                                        Trixi.NonConservativeLocal(),
                                                                        noncons) .*
                            flux_nonconservative_powell_local_symmetric(u_ll, u_rr, 1,
                                                                        equations,
                                                                        Trixi.NonConservativeSymmetric(),
                                                                        noncons)
        end

        @test flux_noncons ≈
              flux_nonconservative_powell_local_symmetric(u_ll, u_rr, 1, equations)
    end

    # Implementation for meshes with normal_direction
    for (orientation, normal_direction) in enumerate((SVector(1.0, 0.0),
                                                      SVector(0.0, 1.0)))
        flux_noncons = zero(u_ll)
        for noncons in 1:Trixi.n_nonconservative_terms(flux_nonconservative_powell_local_symmetric)
            flux_noncons += flux_nonconservative_powell_local_symmetric(u_ll,
                                                                        normal_direction,
                                                                        equations,
                                                                        Trixi.NonConservativeLocal(),
                                                                        noncons) .*
                            flux_nonconservative_powell_local_symmetric(u_ll, u_rr,
                                                                        normal_direction,
                                                                        equations,
                                                                        Trixi.NonConservativeSymmetric(),
                                                                        noncons)
        end

        @test flux_noncons ≈
              flux_nonconservative_powell_local_symmetric(u_ll, u_rr, normal_direction,
                                                          equations)
        @test flux_noncons ≈
              flux_nonconservative_powell_local_symmetric(u_ll, u_rr, orientation,
                                                          equations)
    end

    ## Tests for flux_nonconservative_powell_local_jump
    # Implementation for meshes with orientation
    for orientation in 1:2
        flux_noncons = zero(u_ll)
        for noncons in 1:Trixi.n_nonconservative_terms(flux_nonconservative_powell_local_jump)
            flux_noncons += flux_nonconservative_powell_local_jump(u_ll, 1, equations,
                                                                   Trixi.NonConservativeLocal(),
                                                                   noncons) .*
                            flux_nonconservative_powell_local_jump(u_ll, u_rr, 1,
                                                                   equations,
                                                                   Trixi.NonConservativeJump(),
                                                                   noncons)
        end

        @test flux_noncons ≈
              flux_nonconservative_powell_local_jump(u_ll, u_rr, 1, equations)
    end

    # Implementation for meshes with normal_direction
    for (orientation, normal_direction) in enumerate((SVector(1.0, 0.0),
                                                      SVector(0.0, 1.0)))
        flux_noncons = zero(u_ll)
        for noncons in 1:Trixi.n_nonconservative_terms(flux_nonconservative_powell_local_jump)
            flux_noncons += flux_nonconservative_powell_local_jump(u_ll,
                                                                   normal_direction,
                                                                   equations,
                                                                   Trixi.NonConservativeLocal(),
                                                                   noncons) .*
                            flux_nonconservative_powell_local_jump(u_ll, u_rr,
                                                                   normal_direction,
                                                                   equations,
                                                                   Trixi.NonConservativeJump(),
                                                                   noncons)
        end

        @test flux_noncons ≈
              flux_nonconservative_powell_local_jump(u_ll, u_rr, normal_direction,
                                                     equations)
        @test flux_noncons ≈
              flux_nonconservative_powell_local_jump(u_ll, u_rr, orientation,
                                                     equations)
    end
end
end
end #module
