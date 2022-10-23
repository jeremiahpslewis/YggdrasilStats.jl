using Test
using YggRepology

@testset "YggRepology utils" begin
    @test get_toml_file("JuliaBinaryWrappers/bmon_jll.jl", "Project.toml")["version"] >= "3"

    @test get_readme("JuliaBinaryWrappers/bmon_jll.jl") isa String

    @test occursin(
        "git repository: ",
        extract_readme_metadata(get_readme("JuliaBinaryWrappers/DuckDB_jll.jl"))[:source_url][1],
    )

    @test occursin(
        "git repository: ",
        get_readme_metadata("JuliaBinaryWrappers/DuckDB_jll.jl")[:source_url][1],
    )
    
    @test get_toml_metadata("JuliaBinaryWrappers/DuckDB_jll.jl")[:version] >= "0.2.5"

    drop_url_from_list([""]
end


    # myauth = GitHub.authenticate(ENV["GITHUB_TOKEN"])
    # binary_repositories = repos("JuliaBinaryWrappers"; auth=myauth)

    # repository_list = binary_repositories[1]
    # repository = repository_list[1]

    # repository_list_ = repository_list[101:200]
    # repository = repository_list[1]
    # repository_name = repository.full_name

    # get_binary_info(repository)
    # full_binary_metadata = [
    #     get_binary_info(repository) for
    #     repository in repository_list if repository.updated_at > Date("2021-01-01")
    # ]

    # export_all_binary_info()
    # get_all_binary_info()
