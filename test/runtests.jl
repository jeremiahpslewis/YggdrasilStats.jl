using Test
using YggdrasilStats: YggdrasilStats, get_version_vars_from_build_tarballs, get_version_vars
using GitHub
using Dates

@testset "YggdrasilStats utils" begin
    @test YggdrasilStats.get_toml_file(
        "JuliaBinaryWrappers/DuckDB_jll.jl",
        "Project.toml",
        "main",
    )["version"] >= "0.2"

    @test YggdrasilStats.get_readme("JuliaBinaryWrappers/DuckDB_jll.jl", "main") isa String

    @test occursin(
        "git repository: ",
        YggdrasilStats.extract_readme_metadata(
            YggdrasilStats.get_readme("JuliaBinaryWrappers/DuckDB_jll.jl", "main"),
        )[:source_url][1],
    )

    @test occursin(
        "git repository: ",
        YggdrasilStats.get_readme_metadata("JuliaBinaryWrappers/DuckDB_jll.jl", "main")[:source_url][1],
    )

    @test YggdrasilStats.get_toml_metadata("JuliaBinaryWrappers/DuckDB_jll.jl", "main")[:version] >=
          "0.2.5"

    @test YggdrasilStats.drop_url_from_list([
        "git repository: https://github.com/duckdb/duckdb.git (revision: `7c111322de1095436350f95e33c5553b09302165`)",
    ]) == "https://github.com/duckdb/duckdb.git"

    @test [
        keys(
            YggdrasilStats.get_binary_info(
                GitHub.Repo(;
                    full_name = "JuliaBinaryWrappers/DuckDB_jll.jl",
                    name = "DuckDB_jll.jl",
                    default_branch = "main",
                    updated_at = Date("2021-01-01"),
                    pushed_at = Date("2021-01-01"),
                ),
            ),
        )...,
    ] == [:update_date, :pushed_at, :binary_name, :version, :source_url, :recipe_url]

    @test YggdrasilStats.get_patch_directories([
        "files in directory, relative to originating `build_tarballs.jl`: [`./bundled`](https://github.com/JuliaPackaging/Yggdrasil/tree/79392e93b061260f0982507eb5ed3f697e169f11/B/Blosc/bundled)",
    ]) ==
          "https://github.com/JuliaPackaging/Yggdrasil/tree/79392e93b061260f0982507eb5ed3f697e169f11/B/Blosc/bundled"
end

@testset "YggdrasilStats Integration Tests" begin
    full_binary_metadata = YggdrasilStats.gather_all_binary_info(; maxrepos = 10)
    @test full_binary_metadata isa Array
    @test length(full_binary_metadata) == 10
end

@testset "get_version_vars_from_build_tarballs" begin
    url = "https://github.com/JuliaPackaging/Yggdrasil/blob/04fc78a66f5149ee7d459e9e5a568dedd2b7214a/A/ABC/build_tarballs.jl"
    @test length(get_version_vars("version = 1.1; a_version = 1.3")[1]) == 2
    @test length(get_version_vars_from_build_tarballs(url)) == 2
end
