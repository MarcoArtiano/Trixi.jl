module TestExamplesP4estMesh3D

using Test
using Trixi

include("test_trixi.jl")

EXAMPLES_DIR = joinpath(examples_dir(), "p4est_3d_dgsem")

# Start with a clean environment: remove Trixi.jl output directory if it exists
outdir = "out"
isdir(outdir) && rm(outdir, recursive = true)

@testset "P4estMesh3D" begin
#! format: noindent

@trixi_testset "elixir_advection_basic.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_advection_basic.jl"),
                        # Expected errors are exactly the same as with TreeMesh!
                        l2=[0.00016263963870641478],
                        linf=[0.0014537194925779984])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_advection_unstructured_curved.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_advection_unstructured_curved.jl"),
                        l2=[0.0004750004258546538],
                        linf=[0.026527551737137167])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_advection_nonconforming.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_advection_nonconforming.jl"),
                        l2=[0.00253595715323843],
                        linf=[0.016486952252155795])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_advection_amr.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_advection_amr.jl"),
                        # Expected errors are exactly the same as with TreeMesh!
                        l2=[9.773852895157622e-6],
                        linf=[0.0005853874124926162])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_advection_amr_unstructured_curved.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_advection_amr_unstructured_curved.jl"),
                        l2=[1.6163120948209677e-5],
                        linf=[0.0010572201890564834],
                        tspan=(0.0, 1.0),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_advection_cubed_sphere.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_advection_cubed_sphere.jl"),
                        l2=[0.002006918015656413],
                        linf=[0.027655117058380085])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_advection_restart.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_advection_restart.jl"),
                        l2=[0.002590388934758452],
                        linf=[0.01840757696885409])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_source_terms_nonconforming_unstructured_curved.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_source_terms_nonconforming_unstructured_curved.jl"),
                        l2=[
                            4.070355207909268e-5,
                            4.4993257426833716e-5,
                            5.10588457841744e-5,
                            5.102840924036687e-5,
                            0.00019986264001630542
                        ],
                        linf=[
                            0.0016987332417202072,
                            0.003622956808262634,
                            0.002029576258317789,
                            0.0024206977281964193,
                            0.008526972236273522
                        ],
                        tspan=(0.0, 0.01))

    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_source_terms_nonconforming_unstructured_curved.jl"),
                        surface_flux=FluxPlusDissipation(flux_ranocha,
                                                         DissipationMatrixWintersEtal()),
                        l2=[
                            4.068002997087932e-5,
                            4.4742882348806466e-5,
                            5.101817697733163e-5,
                            5.100410876233901e-5,
                            0.000199848133462063
                        ],
                        linf=[
                            0.0013080357114820806,
                            0.0028524316301083985,
                            0.0019100643150573582,
                            0.0024800222220195955,
                            0.00830424488849335
                        ],
                        tspan=(0.0, 0.01),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_source_terms_nonperiodic.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_source_terms_nonperiodic.jl"),
                        l2=[
                            0.0015106060984283647,
                            0.0014733349038567685,
                            0.00147333490385685,
                            0.001473334903856929,
                            0.0028149479453087093
                        ],
                        linf=[
                            0.008070806335238156,
                            0.009007245083113125,
                            0.009007245083121784,
                            0.009007245083102688,
                            0.01562861968368434
                        ],
                        tspan=(0.0, 1.0))
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_free_stream.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_euler_free_stream.jl"),
                        l2=[
                            5.162664597942288e-15,
                            1.941857343642486e-14,
                            2.0232366394187278e-14,
                            2.3381518645408552e-14,
                            7.083114561232324e-14
                        ],
                        linf=[
                            7.269740365245525e-13,
                            3.289868377720495e-12,
                            4.440087186807773e-12,
                            3.8686831516088205e-12,
                            9.412914891981927e-12
                        ],
                        tspan=(0.0, 0.03))
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_free_stream_extruded.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_euler_free_stream_extruded.jl"),
                        l2=[
                            8.444868392439035e-16,
                            4.889826056731442e-15,
                            2.2921260987087585e-15,
                            4.268460455702414e-15,
                            1.1356712092620279e-14
                        ],
                        linf=[
                            7.749356711883593e-14,
                            2.8792246364872653e-13,
                            1.1121659149182506e-13,
                            3.3228975127030935e-13,
                            9.592326932761353e-13
                        ],
                        tspan=(0.0, 0.1))
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_free_stream_boundaries.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_free_stream_boundaries.jl"),
                        l2=[
                            6.530157034651212e-16, 1.6057829680004379e-15,
                            3.31107455378537e-15, 3.908829498281281e-15,
                            5.048390610424672e-15
                        ],
                        linf=[
                            4.884981308350689e-15, 1.1921019726912618e-14,
                            1.5432100042289676e-14, 2.298161660974074e-14,
                            6.039613253960852e-14
                        ])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_free_stream_boundaries_float32.jl" begin
    # Expected errors are taken from elixir_euler_free_stream_boundaries.jl
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_free_stream_boundaries_float32.jl"),
                        l2=[
                            Float32(6.530157034651212e-16),
                            Float32(1.6057829680004379e-15),
                            Float32(3.31107455378537e-15),
                            Float32(3.908829498281281e-15),
                            Float32(5.048390610424672e-15)
                        ],
                        linf=[
                            Float32(4.884981308350689e-15),
                            Float32(1.1921019726912618e-14),
                            Float32(1.5432100042289676e-14),
                            Float32(2.298161660974074e-14),
                            Float32(6.039613253960852e-14)
                        ],
                        RealT=Float32)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_free_stream_extruded.jl with HLLC FLux" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_euler_free_stream_extruded.jl"),
                        l2=[
                            8.444868392439035e-16,
                            4.889826056731442e-15,
                            2.2921260987087585e-15,
                            4.268460455702414e-15,
                            1.1356712092620279e-14
                        ],
                        linf=[
                            7.749356711883593e-14,
                            4.513472928735496e-13,
                            2.9790059308254513e-13,
                            1.057154364048074e-12,
                            1.6271428648906294e-12
                        ],
                        tspan=(0.0, 0.1),
                        surface_flux=flux_hllc)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_ec.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_euler_ec.jl"),
                        l2=[
                            0.010380390326164493,
                            0.006192950051354618,
                            0.005970674274073704,
                            0.005965831290564327,
                            0.02628875593094754
                        ],
                        linf=[
                            0.3326911600075694,
                            0.2824952141320467,
                            0.41401037398065543,
                            0.45574161423218573,
                            0.8099577682187109
                        ],
                        tspan=(0.0, 0.2),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_ec.jl (flux_chandrashekar)" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_euler_ec.jl"),
                        l2=[
                            0.010368548525287055,
                            0.006216054794583285,
                            0.006020401857347216,
                            0.006019175682769779,
                            0.026228080232814154
                        ],
                        linf=[
                            0.3169376449662026,
                            0.28950510175646726,
                            0.4402523227566396,
                            0.4869168122387365,
                            0.7999141641954051
                        ],
                        tspan=(0.0, 0.2),
                        volume_flux=flux_chandrashekar,)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_sedov.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_euler_sedov.jl"),
                        l2=[
                            7.82070951e-02,
                            4.33260474e-02,
                            4.33260474e-02,
                            4.33260474e-02,
                            3.75260911e-01
                        ],
                        linf=[
                            7.45329845e-01,
                            3.21754792e-01,
                            3.21754792e-01,
                            3.21754792e-01,
                            4.76151527e+00
                        ],
                        tspan=(0.0, 0.3),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_sedov.jl (HLLE)" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_euler_sedov.jl"),
                        l2=[
                            0.09946224487902565,
                            0.04863386374672001,
                            0.048633863746720116,
                            0.04863386374672032,
                            0.3751015774232693
                        ],
                        linf=[
                            0.789241521871487,
                            0.42046970270100276,
                            0.42046970270100276,
                            0.4204697027010028,
                            4.730877375538398
                        ],
                        tspan=(0.0, 0.3),
                        surface_flux=flux_hlle)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_source_terms_nonconforming_earth.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_source_terms_nonconforming_earth.jl"),
                        l2=[
                            6.040180337738628e-6,
                            5.4254175153621895e-6,
                            5.677698851333843e-6,
                            5.8017136892469794e-6,
                            1.3637854615117974e-5
                        ],
                        linf=[
                            0.00013996924184311865,
                            0.00013681539559939893,
                            0.00013681539539733834,
                            0.00013681539541021692,
                            0.00016833038543762058
                        ],
                        # Decrease tolerance of adaptive time stepping to get similar results across different systems
                        abstol=1.0e-11, reltol=1.0e-11,)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_circular_wind_nonconforming.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_circular_wind_nonconforming.jl"),
                        l2=[
                            1.5737711609657832e-7,
                            3.8630261900166194e-5,
                            3.8672287531936816e-5,
                            3.6865116098660796e-5,
                            0.05508620970403884
                        ],
                        linf=[
                            2.268845333053271e-6,
                            0.000531462302113539,
                            0.0005314624461298934,
                            0.0005129931254772464,
                            0.7942778058932163
                        ],
                        tspan=(0.0, 2e2),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_baroclinic_instability.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_baroclinic_instability.jl"),
                        l2=[
                            6.725093801700048e-7,
                            0.00021710076010951073,
                            0.0004386796338203878,
                            0.00020836270267103122,
                            0.07601887903440395
                        ],
                        linf=[
                            1.9107530539574924e-5,
                            0.02980358831035801,
                            0.048476331898047564,
                            0.02200137344113612,
                            4.848310144356219
                        ],
                        tspan=(0.0, 1e2),
                        # Decrease tolerance of adaptive time stepping to get similar results across different systems
                        abstol=1.0e-9, reltol=1.0e-9,)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_source_terms_nonperiodic_hohqmesh.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_source_terms_nonperiodic_hohqmesh.jl"),
                        l2=[
                            0.0042023406458005464,
                            0.004122532789279737,
                            0.0042448149597303616,
                            0.0036361316700401765,
                            0.007389845952982495
                        ],
                        linf=[
                            0.04530610539892499,
                            0.02765695110527666,
                            0.05670295599308606,
                            0.048396544302230504,
                            0.1154589758186293
                        ])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_mhd_alfven_wave_er.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_mhd_alfven_wave_er.jl"),
                        l2=[
                            0.0052864046546744065,
                            0.009963357787771665,
                            0.006635699953141596,
                            0.01295540589311982,
                            0.013939326496053958,
                            0.010192741315114568,
                            0.004631666336074305,
                            0.012267586777052244,
                            0.0018063823439272181
                        ],
                        linf=[
                            0.021741826900806394,
                            0.0470226920658848,
                            0.025036937229995254,
                            0.05043002191230382,
                            0.06018360063552164,
                            0.04338351710391075,
                            0.023607975939848536,
                            0.050740527490335,
                            0.006909064342577296
                        ])
    # Larger values for allowed allocations due to usage of custom
    # integrator which are not *recorded* for the methods from
    # OrdinaryDiffEq.jl
    # Corresponding issue: https://github.com/trixi-framework/Trixi.jl/issues/1877
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 15_000
    end
end

@trixi_testset "elixir_mhd_alfven_wave_nonconforming.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_mhd_alfven_wave_nonconforming.jl"),
                        l2=[
                            0.0001788543743594658,
                            0.000624334205581902,
                            0.00022892869974368887,
                            0.0007223464581156573,
                            0.0006651366626523314,
                            0.0006287275014743352,
                            0.000344484339916008,
                            0.0007179788287557142,
                            8.632896980651243e-7
                        ],
                        linf=[
                            0.0010730565632763867,
                            0.004596749809344033,
                            0.0013235269262853733,
                            0.00468874234888117,
                            0.004719267084104306,
                            0.004228339352211896,
                            0.0037503625505571625,
                            0.005104176909383168,
                            9.738081186490818e-6
                        ],
                        tspan=(0.0, 0.25),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_mhd_alfven_wave_nonperiodic.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_mhd_alfven_wave_nonperiodic.jl"),
                        l2=[
                            0.00017912812934894293,
                            0.000630910737693146,
                            0.0002256138768371346,
                            0.0007301686017397987,
                            0.0006647296256552257,
                            0.0006409790941359089,
                            0.00033986873316986315,
                            0.0007277161123570452,
                            1.3184121257198033e-5
                        ],
                        linf=[
                            0.0012248374096375247,
                            0.004857541490859554,
                            0.001813452620706816,
                            0.004803571938364726,
                            0.005271403957646026,
                            0.004571200760744465,
                            0.002618188297242474,
                            0.005010126350015381,
                            6.309149507784953e-5
                        ],
                        tspan=(0.0, 0.25),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_mhd_shockcapturing_amr.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_mhd_shockcapturing_amr.jl"),
                        l2=[
                            0.0062973565893792004,
                            0.006436273914579104,
                            0.007112703307027178,
                            0.006529650167358523,
                            0.020607452343745017,
                            0.005560993001492338,
                            0.007576418168749763,
                            0.0055721349394598635,
                            3.8269125984310296e-6
                        ],
                        linf=[
                            0.2090718196650192,
                            0.1863884052971854,
                            0.23475479927204168,
                            0.19460789763442982,
                            0.6859816363887359,
                            0.15171474186273914,
                            0.22404690260234983,
                            0.16808957604979002,
                            0.0005083795485317637
                        ],
                        tspan=(0.0, 0.04),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_mhd_amr_entropy_bounded.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_mhd_amr_entropy_bounded.jl"),
                        l2=[
                            0.005430006338127661,
                            0.006186402899876596,
                            0.012171513410597289,
                            0.006181479343504159,
                            0.035068817354117605,
                            0.004967715666538709,
                            0.006592173316509503,
                            0.0050151140388451105,
                            5.146547644807638e-6
                        ],
                        linf=[
                            0.18655204102670386,
                            0.20397573777286138,
                            0.3700839435299759,
                            0.23329319876321034,
                            1.0348619438460904,
                            0.18462694496595722,
                            0.20648634653698617,
                            0.18947822281424997,
                            0.0005083794158781671
                        ],
                        tspan=(0.0, 0.04),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_linearizedeuler_convergence.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_linearizedeuler_convergence.jl"),
                        l2=[
                            0.04452389418193219, 0.03688186699434862,
                            0.03688186699434861, 0.03688186699434858,
                            0.044523894181932186
                        ],
                        linf=[
                            0.2295447498696467, 0.058369658071546704,
                            0.05836965807154648, 0.05836965807154648, 0.2295447498696468
                        ])
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

@trixi_testset "elixir_euler_weak_blast_wave_amr.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR, "elixir_euler_weak_blast_wave_amr.jl"),
                        l2=[
                            0.012046270976464931,
                            0.01894521652831441,
                            0.01951983946363743,
                            0.019748755875702628,
                            0.15017285006198244
                        ],
                        linf=[
                            0.3156585581400839,
                            0.6653806948576124,
                            0.5451454769741236,
                            0.558669830478818,
                            3.6406796982784635
                        ],
                        tspan=(0.0, 0.025),)
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
    # Check for conservation
    state_integrals = Trixi.integrate(sol.u[2], semi)
    initial_state_integrals = analysis_callback.affect!.initial_state_integrals

    @test isapprox(state_integrals[1], initial_state_integrals[1], atol = 1e-13)
    @test isapprox(state_integrals[2], initial_state_integrals[2], atol = 1e-13)
    @test isapprox(state_integrals[3], initial_state_integrals[3], atol = 1e-13)
    @test isapprox(state_integrals[4], initial_state_integrals[4], atol = 1e-13)
    @test isapprox(state_integrals[5], initial_state_integrals[5], atol = 1e-13)
end

@trixi_testset "elixir_euler_OMNERA_M6_wing.jl" begin
    @test_trixi_include(joinpath(EXAMPLES_DIR,
                                 "elixir_euler_OMNERA_M6_wing.jl"),
                        l2=[
                            1.3302852203314697e-7,
                            7.016342225152883e-8,
                            1.0954098970860626e-7,
                            6.834890433113107e-8,
                            3.796737956937651e-7
                        ],
                        linf=[
                            0.08856648749331164,
                            0.07431651477033197,
                            0.08791247483932041,
                            0.012973811024139751,
                            0.25575828277482016
                        ],
                        tspan=(0.0, 5e-8))
    # Ensure that we do not have excessive memory allocations
    # (e.g., from type instabilities)
    let
        t = sol.t[end]
        u_ode = sol.u[end]
        du_ode = similar(u_ode)
        @test (@allocated Trixi.rhs!(du_ode, u_ode, semi, t)) < 1000
    end
end

# Multi-ion MHD tests
include("test_p4est_3d_mhdmultiion.jl")
end

# Clean up afterwards: delete Trixi.jl output directory
@test_nowarn rm(outdir, recursive = true)

end # module
