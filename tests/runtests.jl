using Test
using YggRepology

@testset "YggRepology utils" begin
    @test get_toml_file("JuliaBinaryWrappers/bmon_jll.jl", "Project.toml")["version"] >= "3"

    @test get_readme("JuliaBinaryWrappers/bmon_jll.jl") isa String

    @test occursin(
        "git repository: ",
        extract_readme_metadata(get_readme("JuliaBinaryWrappers/DuckDB_jll.jl"))[:source_url][1],
    )
end
